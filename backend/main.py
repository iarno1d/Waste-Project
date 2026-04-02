from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import io
from PIL import Image
import uvicorn
import os

app = FastAPI(title="Garbage Classification API")

# ✅ CORS — allow Flutter web from any origin
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Load YOLO model
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "best.pt")

if not os.path.exists(MODEL_PATH):
    print(f"⚠️  {MODEL_PATH} not found, loading default yolov8n.pt")
    model = YOLO("yolov8n.pt")
else:
    model = YOLO(MODEL_PATH)
    print(f"✅ Loaded model: {MODEL_PATH}")
    print(f"✅ Classes: {model.names}")


def is_biodegradable(label: str) -> bool:
    """Map YOLO class label to bio / non-bio category."""
    bio_keywords = [
        "bio", "organic", "food", "leaf", "vegetable",
        "fruit", "paper", "cardboard", "wood"
    ]
    return any(k in label.lower() for k in bio_keywords)


@app.get("/")
async def root():
    return {
        "message": "Garbage Classification API is running",
        "model": MODEL_PATH,
        "classes": model.names,
    }


@app.get("/health")
async def health():
    return {
        "status": "ok",
        "model": MODEL_PATH,
        "classes_count": len(model.names),
    }


@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    # ✅ Validate file type
    is_image = image.content_type and image.content_type.startswith("image/")
    is_image_ext = image.filename and image.filename.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))
    
    if not (is_image or is_image_ext):
        raise HTTPException(status_code=400, detail="File must be an image.")

    contents = await image.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file uploaded.")

    try:
        img = Image.open(io.BytesIO(contents)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read image file.")

    # ✅ Run YOLO inference
    try:
        print(f"--- Inferencing image ({img.size[0]}x{img.size[1]}) ---")
        # Go lower (e.g., 0.05): More items detected, but more chance of mistakes (false positives).
        # Go higher (e.g., 0.50): Fewer items detected, but they will be much more accurate.
        results = model.predict(source=img, save=False, verbose=False, conf=0.1)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model inference failed: {str(e)}")

    detections = []
    bio_count = 0
    non_bio_count = 0

    for r in results:
        for box in r.boxes:
            class_idx = int(box.cls[0])
            label = model.names[class_idx]
            conf = float(box.conf[0])
            bio = is_biodegradable(label)

            if bio:
                bio_count += 1
            else:
                non_bio_count += 1

            detections.append({
                "label": label,
                "confidence": round(conf, 4),
                "category": "bio" if bio else "non_bio",
                "index": class_idx,
            })

    # Sort by confidence descending
    detections.sort(key=lambda x: x["confidence"], reverse=True)

    total = len(detections)
    bio_percent = round((bio_count / total * 100), 2) if total > 0 else 0.0
    non_bio_percent = round((non_bio_count / total * 100), 2) if total > 0 else 0.0

    top_pred = detections[0] if detections else {
        "label": "unknown",
        "confidence": 0.0,
        "category": "unknown",
        "index": -1,
    }

    return {
        # ✅ Flutter reads these two fields
        "top_prediction": {
            "label": top_pred["label"],
            "confidence": top_pred["confidence"],
            "category": top_pred["category"],
        },
        "predictions": detections,   # ← Flutter expects "predictions" not "detections"

        # ✅ Extra summary for the UI
        "summary": {
            "total_detections": total,
            "bio_count": bio_count,
            "non_bio_count": non_bio_count,
            "bio_percentage": bio_percent,
            "non_bio_percentage": non_bio_percent,
        },
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)