from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path


def _parse_float_list(raw_value: str, *, expected_length: int) -> list[float]:
    values = [float(item.strip()) for item in raw_value.split(",") if item.strip()]
    if len(values) != expected_length:
        raise ValueError(
            f"Expected {expected_length} comma-separated values, got {len(values)}."
        )
    return values


def _parse_str_list(raw_value: str) -> list[str]:
    return [item.strip() for item in raw_value.split(",") if item.strip()]


@dataclass(slots=True)
class Settings:
    model_path: Path
    labels_path: Path | None
    model_factory: str | None
    model_factory_kwargs: dict[str, object]
    image_size: int
    normalize_mean: list[float]
    normalize_std: list[float]
    device: str
    top_k: int
    allow_origins: list[str]
    class_names: list[str] | None

    @classmethod
    def from_env(cls) -> "Settings":
        labels_path = os.getenv("LABELS_PATH", "").strip()
        model_factory = os.getenv("MODEL_FACTORY", "").strip()
        class_names = os.getenv("CLASS_NAMES", "").strip()
        allow_origins = os.getenv("ALLOW_ORIGINS", "*").strip()
        factory_kwargs = os.getenv("MODEL_FACTORY_KWARGS", "{}").strip()

        return cls(
            model_path=Path(os.getenv("MODEL_PATH", "backend/model/model.pt")),
            labels_path=Path(labels_path) if labels_path else None,
            model_factory=model_factory or None,
            model_factory_kwargs=json.loads(factory_kwargs),
            image_size=int(os.getenv("IMAGE_SIZE", "224")),
            normalize_mean=_parse_float_list(
                os.getenv("NORMALIZE_MEAN", "0.485,0.456,0.406"),
                expected_length=3,
            ),
            normalize_std=_parse_float_list(
                os.getenv("NORMALIZE_STD", "0.229,0.224,0.225"),
                expected_length=3,
            ),
            device=os.getenv("DEVICE", "cpu"),
            top_k=int(os.getenv("TOP_K", "3")),
            allow_origins=_parse_str_list(allow_origins) or ["*"],
            class_names=_parse_str_list(class_names) or None,
        )

