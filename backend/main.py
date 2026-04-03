from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.staticfiles import StaticFiles
import json
import uuid
from datetime import datetime
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

# ✅ Setup local storage directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USER_DATA_DIR = os.path.join(BASE_DIR, "user_data")
os.makedirs(USER_DATA_DIR, exist_ok=True)

# ✅ Serve uploaded images
app.mount("/user_data", StaticFiles(directory=USER_DATA_DIR), name="user_data")


# ✅ Load YOLO model
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
async def predict(
    image: UploadFile = File(...),
    user_id: str = Form(None),
    location: str = Form(None)
):
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

    response_data = {
        # ✅ Flutter reads these two fields
        "top_prediction": {
            "label": top_pred["label"],
            "confidence": top_pred["confidence"],
            "category": top_pred["category"],
        },
        "predictions": detections,

        # ✅ Extra summary for the UI
        "summary": {
            "total_detections": total,
            "bio_count": bio_count,
            "non_bio_count": non_bio_count,
            "bio_percentage": bio_percent,
            "non_bio_percentage": non_bio_percent,
        },
    }

    # If user_id is provided, save image and JSON to user's folder
    if user_id:
        user_dir = os.path.join(USER_DATA_DIR, user_id)
        os.makedirs(user_dir, exist_ok=True)
        img_id = str(uuid.uuid4())
        
        response_data['id'] = img_id
        response_data['created_at'] = datetime.utcnow().isoformat()
        response_data['status'] = 'Pending'
        if location:
            response_data['location'] = location
        
        # Save image
        img_filename = f"{img_id}.jpg"
        img_path = os.path.join(user_dir, img_filename)
        img.save(img_path)
        
        # Save JSON
        json_filename = f"{img_id}.json"
        json_path = os.path.join(user_dir, json_filename)
        with open(json_path, "w") as f:
            json.dump(response_data, f, indent=4)

    return response_data

@app.get("/reports/{user_id}")
async def get_reports(user_id: str):
    user_dir = os.path.join(USER_DATA_DIR, user_id)
    if not os.path.exists(user_dir):
        return {"reports": []}
        
    reports = []
    # Find all json files
    for filename in os.listdir(user_dir):
        if filename.endswith(".json"):
            with open(os.path.join(user_dir, filename), "r") as f:
                try:
                    data = json.load(f)
                    reports.append(data)
                except Exception:
                    pass
                    
    # Sort by created_at descending
    reports.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return {"reports": reports}

@app.get("/admin/reports")
async def get_all_reports():
    reports = []
    if not os.path.exists(USER_DATA_DIR):
        return {"reports": []}
        
    for user_folder in os.listdir(USER_DATA_DIR):
        user_dir = os.path.join(USER_DATA_DIR, user_folder)
        if os.path.isdir(user_dir):
            for filename in os.listdir(user_dir):
                if filename.endswith(".json"):
                    try:
                        with open(os.path.join(user_dir, filename), "r") as f:
                            data = json.load(f)
                            data["user_email"] = user_folder # The folder IS the email now
                            reports.append(data)
                    except Exception:
                        pass
                        
    reports.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return {"reports": reports}

from pydantic import BaseModel

class StatusUpdate(BaseModel):
    status: str

@app.put("/admin/reports/{user_email}/{ticket_id}/status")
async def update_status(user_email: str, ticket_id: str, payload: StatusUpdate):
    user_dir = os.path.join(USER_DATA_DIR, user_email)
    json_path = os.path.join(user_dir, f"{ticket_id}.json")
    
    if not os.path.exists(json_path):
        raise HTTPException(status_code=404, detail="Ticket not found")
        
    with open(json_path, "r") as f:
        data = json.load(f)
        
    data["status"] = payload.status
    
    with open(json_path, "w") as f:
        json.dump(data, f, indent=4)
        
    return {"message": "Status updated successfully", "new_status": payload.status}


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)