import uuid
from typing import List, Dict, Any, Optional
from sqlalchemy import case, desc
from sqlalchemy.orm import Session
from local_persistence.models import HistoryModel, FavoriteModel
from local_persistence.schemas import HistoryRecordCreate, HistoryRecordResponse


class LocalHistoryRepository:
    """Repository for managing history records in the local SQLite database."""

    def __init__(self, db: Session):
        self.db = db

    def save(self, history_data: dict) -> dict:
        """
        Inserts or updates a history record.

        Validates history_data against HistoryRecordCreate schema.
        Generates a UUID v4 string if 'id' is not provided.
        """
        validated = HistoryRecordCreate(**history_data)
        record_id = validated.id or str(uuid.uuid4())

        try:
            history_obj = (
                self.db.query(HistoryModel)
                .filter(HistoryModel.id == record_id)
                .first()
            )

            if history_obj:
                history_obj.input = validated.input
                history_obj.mode = validated.mode
                history_obj.result_json = validated.result_json
            else:
                history_obj = HistoryModel(
                    id=record_id,
                    input=validated.input,
                    mode=validated.mode,
                    result_json=validated.result_json,
                )
                self.db.add(history_obj)

            self.db.commit()
            self.db.refresh(history_obj)

            # Check if favorited
            fav_exists = (
                self.db.query(FavoriteModel)
                .filter(FavoriteModel.history_id == history_obj.id)
                .first()
                is not None
            )

            return HistoryRecordResponse(
                id=history_obj.id,
                input=history_obj.input,
                mode=history_obj.mode,
                result_json=history_obj.result_json,
                is_favorite=fav_exists,
                created_at=history_obj.created_at,
            ).model_dump()
        except Exception:
            self.db.rollback()
            raise

    def save_and_favorite(self, history_data: dict) -> dict:
        """
        Atomically saves a History record and marks it as Favorite in a single transaction.

        If any error occurs during saving or favoriting, the transaction is completely rolled back.
        """
        validated = HistoryRecordCreate(**history_data)
        record_id = validated.id or str(uuid.uuid4())

        try:
            # 1. Upsert History record
            history_obj = (
                self.db.query(HistoryModel)
                .filter(HistoryModel.id == record_id)
                .first()
            )

            if history_obj:
                history_obj.input = validated.input
                history_obj.mode = validated.mode
                history_obj.result_json = validated.result_json
            else:
                history_obj = HistoryModel(
                    id=record_id,
                    input=validated.input,
                    mode=validated.mode,
                    result_json=validated.result_json,
                )
                self.db.add(history_obj)

            self.db.flush()

            # 2. Add Favorite entry if not present
            fav_obj = (
                self.db.query(FavoriteModel)
                .filter(FavoriteModel.history_id == history_obj.id)
                .first()
            )
            if not fav_obj:
                fav_obj = FavoriteModel(history_id=history_obj.id)
                self.db.add(fav_obj)

            # Commit atomic transaction
            self.db.commit()
            self.db.refresh(history_obj)

            return HistoryRecordResponse(
                id=history_obj.id,
                input=history_obj.input,
                mode=history_obj.mode,
                result_json=history_obj.result_json,
                is_favorite=True,
                created_at=history_obj.created_at,
            ).model_dump()
        except Exception:
            self.db.rollback()
            raise

    def list_visible(self, limit: int = 20) -> List[dict]:
        """
        Fetches up to `limit` visible history records.

        Sorting Rule (F-001):
        Favorited items (is_favorite == True) take priority, followed by created_at DESC.

        Data Retention Rule (F-001):
        The limit is ONLY a display limit and never auto-deletes records from the DB.
        """
        is_fav_expr = case(
            (FavoriteModel.history_id.isnot(None), True),
            else_=False,
        )

        query = (
            self.db.query(HistoryModel, is_fav_expr.label("is_favorite"))
            .outerjoin(FavoriteModel, HistoryModel.id == FavoriteModel.history_id)
            .order_by(desc(is_fav_expr), desc(HistoryModel.created_at))
            .limit(limit)
        )

        results = query.all()
        records = []
        for history_obj, is_fav in results:
            rec = HistoryRecordResponse(
                id=history_obj.id,
                input=history_obj.input,
                mode=history_obj.mode,
                result_json=history_obj.result_json,
                is_favorite=bool(is_fav),
                created_at=history_obj.created_at,
            ).model_dump()
            records.append(rec)

        return records

    def get_by_id(self, history_id: str) -> Optional[dict]:
        """Fetch a single history record by ID if it exists."""
        history_obj = (
            self.db.query(HistoryModel)
            .filter(HistoryModel.id == history_id)
            .first()
        )
        if not history_obj:
            return None

        fav_exists = (
            self.db.query(FavoriteModel)
            .filter(FavoriteModel.history_id == history_id)
            .first()
            is not None
        )

        return HistoryRecordResponse(
            id=history_obj.id,
            input=history_obj.input,
            mode=history_obj.mode,
            result_json=history_obj.result_json,
            is_favorite=fav_exists,
            created_at=history_obj.created_at,
        ).model_dump()

    def delete(self, history_id: str) -> None:
        """
        Deletes a single history record.
        Cascades deletion to the corresponding favorite record via DB Foreign Key CASCADE.
        """
        try:
            history_obj = (
                self.db.query(HistoryModel)
                .filter(HistoryModel.id == history_id)
                .first()
            )
            if history_obj:
                self.db.delete(history_obj)
                self.db.commit()
        except Exception:
            self.db.rollback()
            raise

    def clear(self) -> None:
        """Clears all history records (and cascaded favorites)."""
        try:
            self.db.query(HistoryModel).delete()
            self.db.commit()
        except Exception:
            self.db.rollback()
            raise
