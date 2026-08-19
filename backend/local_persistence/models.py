from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
from local_persistence.database import Base


class HistoryModel(Base):
    """SQLAlchemy ORM model for history records."""
    __tablename__ = "history"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    input = Column(Text, nullable=False)
    mode = Column(String(20), nullable=False)
    result_json = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationship to FavoriteModel
    favorite = relationship(
        "FavoriteModel",
        back_populates="history",
        uselist=False,
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        Index("idx_history_created_at", created_at.desc()),
    )


class FavoriteModel(Base):
    """SQLAlchemy ORM model for favorited records."""
    __tablename__ = "favorites"

    history_id = Column(
        String(36),
        ForeignKey("history.id", ondelete="CASCADE"),
        primary_key=True,
    )
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationship to HistoryModel
    history = relationship("HistoryModel", back_populates="favorite")


class CacheModel(Base):
    """SQLAlchemy ORM model for analysis cache entries."""
    __tablename__ = "analysis_cache"

    key = Column(String(255), primary_key=True)
    output_json = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    __table_args__ = (
        Index("idx_cache_created_at", created_at.asc()),
    )


