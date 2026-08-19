"""
Repository package for LingoLens backend local persistence.
"""
from local_persistence.repositories.history_repository import LocalHistoryRepository
from local_persistence.repositories.favorite_repository import LocalFavoriteRepository
from local_persistence.repositories.cache_repository import LocalCacheRepository

__all__ = [
    "LocalHistoryRepository",
    "LocalFavoriteRepository",
    "LocalCacheRepository",
]
