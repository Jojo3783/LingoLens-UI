from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, field_validator


class HistoryRecordCreate(BaseModel):
    """Pydantic schema for creating a history record."""
    id: Optional[str] = None
    input: str
    mode: str
    result_json: str

    @field_validator("input")
    @classmethod
    def validate_input(cls, v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("input must be a string")
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("input must not be empty or whitespace only")
        if len(trimmed) > 2000:
            raise ValueError("input length must not exceed 2000 characters")
        return trimmed

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, v: str) -> str:
        if v not in ("reading", "expression"):
            raise ValueError("mode must be 'reading' or 'expression'")
        return v


class HistoryRecordResponse(BaseModel):
    """Pydantic schema for returning history records."""
    id: str
    input: str
    mode: str
    result_json: str
    is_favorite: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CacheEntryCreate(BaseModel):
    """Pydantic schema for creating or updating an analysis cache entry."""
    key: str
    output_json: str

    @field_validator("key")
    @classmethod
    def validate_key(cls, v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("key must be a string")
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("key must not be empty or whitespace only")
        if len(trimmed) > 255:
            raise ValueError("key length must not exceed 255 characters")
        return trimmed

    @field_validator("output_json")
    @classmethod
    def validate_output_json(cls, v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("output_json must be a string")
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("output_json must not be empty or whitespace only")
        return trimmed


class CacheEntryResponse(BaseModel):
    """Pydantic schema for returning cache entries."""
    key: str
    output_json: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

