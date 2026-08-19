from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session

from local_persistence.models import CacheModel
from local_persistence.schemas import CacheEntryCreate, CacheEntryResponse


class LocalCacheRepository:
    """
    Repository for managing analysis cache entries in the local SQLite database.
    Enforces automatic LRU/FIFO eviction when capacity limit (default 30) is reached,
    and guarantees complete data isolation from History and Favorite tables.
    """

    def __init__(self, db: Session, max_capacity: int = 30):
        self.db = db
        self.max_capacity = max_capacity

    def get(self, key: str) -> Optional[dict]:
        """
        Retrieves a cached entry by key.
        Returns a serialized dictionary via CacheEntryResponse or None if not found.
        """
        if not key or not isinstance(key, str):
            return None

        cache_obj = (
            self.db.query(CacheModel)
            .filter(CacheModel.key == key.strip())
            .first()
        )
        if not cache_obj:
            return None

        return CacheEntryResponse(
            key=cache_obj.key,
            output_json=cache_obj.output_json,
            created_at=cache_obj.created_at,
        ).model_dump()

    def put(self, entry_data: dict) -> dict:
        """
        Inserts or updates a cache entry.
        If inserting a new key and count >= max_capacity, automatically evicts the oldest entry.
        """
        validated = CacheEntryCreate(**entry_data)
        now = datetime.now(timezone.utc)

        try:
            cache_obj = (
                self.db.query(CacheModel)
                .filter(CacheModel.key == validated.key)
                .first()
            )

            if cache_obj:
                # Update existing key content and timestamp
                cache_obj.output_json = validated.output_json
                cache_obj.created_at = now
            else:
                # New key: check capacity and evict oldest if needed
                current_count = self.count()
                if current_count >= self.max_capacity:
                    oldest_obj = (
                        self.db.query(CacheModel)
                        .order_by(CacheModel.created_at.asc())
                        .first()
                    )
                    if oldest_obj:
                        self.db.delete(oldest_obj)
                        self.db.flush()

                cache_obj = CacheModel(
                    key=validated.key,
                    output_json=validated.output_json,
                    created_at=now,
                )
                self.db.add(cache_obj)

            self.db.commit()
            self.db.refresh(cache_obj)

            return CacheEntryResponse(
                key=cache_obj.key,
                output_json=cache_obj.output_json,
                created_at=cache_obj.created_at,
            ).model_dump()
        except Exception:
            self.db.rollback()
            raise

    def clear(self) -> None:
        """
        Deletes all records ONLY from analysis_cache table.
        MUST NEVER affect or cascade to history or favorites tables.
        """
        try:
            self.db.query(CacheModel).delete()
            self.db.commit()
        except Exception:
            self.db.rollback()
            raise

    def count(self) -> int:
        """Returns the total number of cached entries in the database."""
        return self.db.query(CacheModel).count()
