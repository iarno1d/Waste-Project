from __future__ import annotations

from functools import lru_cache

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings
from .model_loader import InferenceService


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings.from_env()


@lru_cache(maxsize=1)
def get_service() -> InferenceService:
    return InferenceService(get_settings())


app = FastAPI(
    title="Garbage Classification API",
    version="1.0.0",
    summary="Uploads an image and returns predicted garbage classes.",
)

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def healthcheck() -> dict[str, object]:
    try:
        service = get_service()
        labels_loaded = len(service.labels) if service.labels else 0
        return {
            "status": "ok",
            "model_path": str(service.settings.model_path),
            "labels_loaded": labels_loaded,
        }
    except Exception as error:
        return {"status": "error", "detail": str(error)}


@app.post("/predict")
async def predict(
    image: UploadFile = File(...),
    top_k: int | None = Form(default=None),
) -> dict[str, object]:
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload must be an image file.")

    content = await image.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file was empty.")

    try:
        return get_service().predict(content, top_k=top_k)
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error
