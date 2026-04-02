from __future__ import annotations

import importlib
from io import BytesIO
from pathlib import Path
from typing import Any

import numpy as np
import torch
from PIL import Image

from .config import Settings


class InferenceService:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.device = torch.device(settings.device)
        self.model = self._load_model()
        self.labels = self._load_labels()

    def _load_model(self) -> torch.nn.Module:
        model_path = self.settings.model_path
        if not model_path.exists():
            raise FileNotFoundError(
                f"Model file was not found at '{model_path}'. "
                "Place your .pt file there or update MODEL_PATH."
            )

        if self.settings.model_factory:
            return self._load_checkpoint_with_factory(model_path)

        try:
            model = torch.jit.load(str(model_path), map_location=self.device)
            model.eval()
            return model
        except Exception:
            loaded = torch.load(
                model_path,
                map_location=self.device,
                weights_only=False,
            )
            if isinstance(loaded, torch.nn.Module):
                loaded.eval()
                return loaded
            raise ValueError(
                "The .pt file is not a TorchScript model and does not contain a "
                "directly loadable PyTorch module. Set MODEL_FACTORY to a callable "
                "that returns your model architecture so the checkpoint can be loaded."
            )

    def _load_checkpoint_with_factory(self, model_path: Path) -> torch.nn.Module:
        factory_path = self.settings.model_factory
        if not factory_path or ":" not in factory_path:
            raise ValueError(
                "MODEL_FACTORY must look like 'some.module:create_model'."
            )

        module_name, callable_name = factory_path.split(":", maxsplit=1)
        module = importlib.import_module(module_name)
        factory = getattr(module, callable_name)
        model = factory(**self.settings.model_factory_kwargs)
        checkpoint = torch.load(
            model_path,
            map_location=self.device,
            weights_only=False,
        )

        if isinstance(checkpoint, dict):
            state_dict = checkpoint.get("state_dict", checkpoint)
        else:
            state_dict = checkpoint

        missing_keys, unexpected_keys = model.load_state_dict(
            state_dict,
            strict=False,
        )
        if missing_keys or unexpected_keys:
            message_parts = []
            if missing_keys:
                message_parts.append(f"missing keys: {missing_keys}")
            if unexpected_keys:
                message_parts.append(f"unexpected keys: {unexpected_keys}")
            raise ValueError(
                "Checkpoint could not be loaded cleanly into the supplied model "
                f"factory ({'; '.join(message_parts)})."
            )

        model.to(self.device)
        model.eval()
        return model

    def _load_labels(self) -> list[str] | None:
        if self.settings.class_names:
            return self.settings.class_names

        labels_path = self.settings.labels_path
        if not labels_path:
            return None

        if not labels_path.exists():
            raise FileNotFoundError(
                f"Labels file was not found at '{labels_path}'. "
                "Create the file or remove LABELS_PATH."
            )

        labels = [
            line.strip()
            for line in labels_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
        return labels or None

    def predict(self, image_bytes: bytes, *, top_k: int | None = None) -> dict[str, Any]:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        tensor = self._preprocess(image)

        with torch.inference_mode():
            output = self.model(tensor)
            if isinstance(output, (tuple, list)):
                output = output[0]
            scores = output.squeeze(0)
            probabilities = torch.softmax(scores, dim=-1)

        requested_top_k = max(1, top_k or self.settings.top_k)
        top_values, top_indices = torch.topk(
            probabilities,
            k=min(requested_top_k, probabilities.numel()),
        )

        predictions: list[dict[str, Any]] = []
        for score, index in zip(top_values.tolist(), top_indices.tolist(), strict=False):
            label = self._resolve_label(index)
            predictions.append(
                {
                    "label": label,
                    "confidence": round(float(score), 4),
                    "index": int(index),
                }
            )

        return {
            "top_prediction": predictions[0],
            "predictions": predictions,
            "image_size": self.settings.image_size,
        }

    def _preprocess(self, image: Image.Image) -> torch.Tensor:
        resized = image.resize(
            (self.settings.image_size, self.settings.image_size),
            Image.Resampling.BILINEAR,
        )
        array = np.asarray(resized, dtype=np.float32) / 255.0
        normalized = (array - np.array(self.settings.normalize_mean)) / np.array(
            self.settings.normalize_std
        )
        tensor = torch.from_numpy(normalized.transpose(2, 0, 1)).float().unsqueeze(0)
        return tensor.to(self.device)

    def _resolve_label(self, index: int) -> str:
        if self.labels and index < len(self.labels):
            return self.labels[index]
        return f"class_{index}"

