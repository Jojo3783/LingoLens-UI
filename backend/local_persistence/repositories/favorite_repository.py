from typing import List
from sqlalchemy import desc
from sqlalchemy.orm import Session
from local_persistence.models import HistoryModel, FavoriteModel
from local_persistence.schemas import HistoryRecordResponse


class LocalFavoriteRepository:
    """Repository for managing favorited records in the local SQLite database."""

    def __init__(self, db: Session):
        self.db = db

    def set_favorite(self, history_id: str, is_favorite: bool) -> None:
        """
        Adds or removes a record from the favorites table.

        If is_favorite is True: Adds to favorites table if history record exists.
        If is_favorite is False: Removes from favorites table.
        Unmarking/removing a favorite MUST NOT delete the underlying History record.
        """
        try:
            fav_obj = (
                self.db.query(FavoriteModel)
                .filter(FavoriteModel.history_id == history_id)
                .first()
            )

            if is_favorite:
                if not fav_obj:
                    history_obj = (
                        self.db.query(HistoryModel)
                        .filter(HistoryModel.id == history_id)
                        .first()
                    )
                    if not history_obj:
                        raise ValueError(
                            f"Cannot favorite: History record '{history_id}' does not exist."
                        )
                    fav_obj = FavoriteModel(history_id=history_id)
                    self.db.add(fav_obj)
            else:
                if fav_obj:
                    self.db.delete(fav_obj)

            self.db.commit()
        except Exception:
            self.db.rollback()
            raise

    def list_all(self) -> List[dict]:
        """
        Lists all favorited history records ordered by created_at DESC.
        """
        query = (
            self.db.query(HistoryModel)
            .join(FavoriteModel, HistoryModel.id == FavoriteModel.history_id)
            .order_by(desc(FavoriteModel.created_at), desc(HistoryModel.created_at))
        )

        results = query.all()
        records = []
        for history_obj in results:
            rec = HistoryRecordResponse(
                id=history_obj.id,
                input=history_obj.input,
                mode=history_obj.mode,
                result_json=history_obj.result_json,
                is_favorite=True,
                created_at=history_obj.created_at,
            ).model_dump()
            records.append(rec)

        return records
