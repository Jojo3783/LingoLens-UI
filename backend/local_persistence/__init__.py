"""
Local persistence layer package for LingoLens backend.
"""
from local_persistence.models import HistoryModel, FavoriteModel, CacheModel
from local_persistence.schemas import (
    HistoryRecordCreate,
    HistoryRecordResponse,
    CacheEntryCreate,
    CacheEntryResponse,
)
from local_persistence.settings_schemas import (
    SettingsModel,
    SettingsResponseDTO,
    SettingsUpdateDTO,
)
from local_persistence.security import SecretKeyManager
from local_persistence.repositories.history_repository import LocalHistoryRepository
from local_persistence.repositories.favorite_repository import LocalFavoriteRepository
from local_persistence.repositories.cache_repository import LocalCacheRepository
from local_persistence.settings_repository import LocalSettingsRepository

__all__ = [
    "HistoryModel",
    "FavoriteModel",
    "CacheModel",
    "HistoryRecordCreate",
    "HistoryRecordResponse",
    "CacheEntryCreate",
    "CacheEntryResponse",
    "SettingsModel",
    "SettingsResponseDTO",
    "SettingsUpdateDTO",
    "SecretKeyManager",
    "LocalHistoryRepository",
    "LocalFavoriteRepository",
    "LocalCacheRepository",
    "LocalSettingsRepository",
]
