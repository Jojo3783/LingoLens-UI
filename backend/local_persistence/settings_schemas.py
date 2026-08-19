from typing import Literal, Optional
from pydantic import BaseModel, ConfigDict, field_validator


class SettingsModel(BaseModel):
    """Internal Pydantic model for stored settings JSON structure."""

    selected_provider: Literal["fake", "openai_responses"] = "fake"
    openai_model: str = "gpt-5-mini"
    history_writes_enabled: bool = True
    encrypted_api_key: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

    @field_validator("openai_model")
    @classmethod
    def validate_openai_model(cls, v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("openai_model must be a string")
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("openai_model must not be empty or whitespace")
        if len(trimmed) > 80:
            raise ValueError("openai_model must not exceed 80 characters")
        return trimmed


class SettingsUpdateDTO(BaseModel):
    """Input DTO for updating local settings."""

    selected_provider: Optional[Literal["fake", "openai_responses"]] = None
    openai_model: Optional[str] = None
    history_writes_enabled: Optional[bool] = None
    openai_api_key: Optional[str] = None

    @field_validator("openai_model")
    @classmethod
    def validate_openai_model(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("openai_model must not be empty or whitespace")
        if len(trimmed) > 80:
            raise ValueError("openai_model must not exceed 80 characters")
        return trimmed


class SettingsResponseDTO(BaseModel):
    """Output DTO for returning settings safely to callers/UI."""

    selected_provider: Literal["fake", "openai_responses"]
    openai_model: str
    history_writes_enabled: bool
    has_api_key: bool
    masked_api_key: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
