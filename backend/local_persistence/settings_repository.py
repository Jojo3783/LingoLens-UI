import json
import logging
import os
from pathlib import Path
from typing import Optional

from local_persistence.security import SecretKeyManager
from local_persistence.settings_schemas import (
    SettingsModel,
    SettingsResponseDTO,
    SettingsUpdateDTO,
)

logger = logging.getLogger(__name__)


class LocalSettingsRepository:
    """
    Repository for persisting local configuration settings to a JSON file.
    Uses atomic file writes and encrypts sensitive API keys via SecretKeyManager.
    """

    def __init__(self, settings_path: Path, secret_manager: SecretKeyManager):
        self.settings_path = Path(settings_path)
        self.secret_manager = secret_manager

    def load_settings(self) -> SettingsModel:
        """
        Reads and parses settings.json.
        Falls back to default SettingsModel if file is missing, corrupted, or invalid.
        """
        if not self.settings_path.exists():
            return SettingsModel()

        try:
            content = self.settings_path.read_text(encoding="utf-8")
            data = json.loads(content)
            return SettingsModel.model_validate(data)
        except (json.JSONDecodeError, Exception) as e:
            logger.warning(
                f"Failed to parse settings file at {self.settings_path} ({e}). "
                "Falling back to default settings."
            )
            return SettingsModel()

    def update_settings(self, dto: SettingsUpdateDTO) -> SettingsResponseDTO:
        """
        Updates settings fields, encrypts API key if provided, and performs atomic file write.
        """
        current_model = self.load_settings()

        # Update general settings if specified in DTO
        if dto.selected_provider is not None:
            current_model.selected_provider = dto.selected_provider
        if dto.openai_model is not None:
            current_model.openai_model = dto.openai_model
        if dto.history_writes_enabled is not None:
            current_model.history_writes_enabled = dto.history_writes_enabled

        # Handle API Key update/clear
        if dto.openai_api_key is not None:
            if dto.openai_api_key.strip():
                cipher_text = self.secret_manager.encrypt_api_key(dto.openai_api_key)
                current_model.encrypted_api_key = cipher_text
            else:
                current_model.encrypted_api_key = None

        # Atomic File Write
        self._atomic_save(current_model)

        return self._to_response_dto(current_model)

    def get_active_api_key(self) -> Optional[str]:
        """
        Decrypts and returns the active plain-text OpenAI API Key in memory.
        Returns None if no API key is set or decryption fails.
        """
        model = self.load_settings()
        if not model.encrypted_api_key:
            return None
        return self.secret_manager.decrypt_api_key(model.encrypted_api_key)

    def clear_api_key(self) -> None:
        """Removes the encrypted API key and persists updated settings atomically."""
        model = self.load_settings()
        model.encrypted_api_key = None
        self._atomic_save(model)

    def _atomic_save(self, model: SettingsModel) -> None:
        """
        Writes serialized model JSON to a temporary file and atomically replaces settings_path.
        """
        self.settings_path.parent.mkdir(parents=True, exist_ok=True)
        tmp_path = self.settings_path.with_suffix(".tmp")

        json_str = model.model_dump_json(indent=2)
        try:
            tmp_path.write_text(json_str, encoding="utf-8")
            os.replace(tmp_path, self.settings_path)
        except Exception as e:
            if tmp_path.exists():
                try:
                    tmp_path.unlink()
                except Exception:
                    pass
            logger.error(f"Atomic save failed for {self.settings_path}: {e}")
            raise

    def _to_response_dto(self, model: SettingsModel) -> SettingsResponseDTO:
        """Converts SettingsModel into a safe SettingsResponseDTO with masked API key."""
        plain_key = (
            self.secret_manager.decrypt_api_key(model.encrypted_api_key)
            if model.encrypted_api_key
            else None
        )
        has_api_key = plain_key is not None and bool(plain_key.strip())
        masked_key = self._mask_key(plain_key) if has_api_key else None

        return SettingsResponseDTO(
            selected_provider=model.selected_provider,
            openai_model=model.openai_model,
            history_writes_enabled=model.history_writes_enabled,
            has_api_key=has_api_key,
            masked_api_key=masked_key,
        )

    @staticmethod
    def _mask_key(plain_key: Optional[str]) -> Optional[str]:
        if not plain_key or not plain_key.strip():
            return None
        key = plain_key.strip()
        if len(key) <= 8:
            return "****"
        return f"{key[:3]}...{key[-4:]}"
