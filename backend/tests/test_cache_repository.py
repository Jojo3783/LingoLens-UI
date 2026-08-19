from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker
from pydantic import ValidationError

from local_persistence.database import Base
from local_persistence.models import HistoryModel, FavoriteModel, CacheModel
from local_persistence.repositories.history_repository import LocalHistoryRepository
from local_persistence.repositories.cache_repository import LocalCacheRepository


@pytest.fixture
def db_session():
    """Fixture providing an in-memory SQLite database session for testing."""
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False}
    )

    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    yield session

    session.close()
    Base.metadata.drop_all(bind=engine)


def test_basic_put_and_get(db_session):
    """Test basic put and get operations for analysis cache."""
    cache_repo = LocalCacheRepository(db_session, max_capacity=30)
    key = "hash_reading_hello_world"
    data = {"key": key, "output_json": '{"translation": "你好世界"}'}

    saved = cache_repo.put(data)
    assert saved["key"] == key
    assert saved["output_json"] == '{"translation": "你好世界"}'
    assert isinstance(saved["created_at"], datetime)

    retrieved = cache_repo.get(key)
    assert retrieved is not None
    assert retrieved["key"] == key
    assert retrieved["output_json"] == '{"translation": "你好世界"}'

    # Querying non-existent key returns None
    assert cache_repo.get("non_existent_key") is None


def test_capacity_eviction_limit_30(db_session):
    """
    Test capacity eviction:
    Inserting 35 unique keys sequentially maintains exactly 30 records,
    verifying that the first 5 inserted keys are properly evicted.
    """
    cache_repo = LocalCacheRepository(db_session, max_capacity=30)

    # Insert 35 unique entries with distinct timestamps
    base_time = datetime.now(timezone.utc) - timedelta(hours=10)

    for i in range(1, 36):
        data = {
            "key": f"key_{i:02d}",
            "output_json": f'{{"result": {i}}}'
        }
        cache_repo.put(data)
        # Update created_at timestamp explicitly to ensure deterministic chronological order
        db_session.query(CacheModel).filter_by(key=f"key_{i:02d}").update(
            {"created_at": base_time + timedelta(minutes=i)}
        )
        db_session.commit()

    # Total count in DB must equal max_capacity (30)
    assert cache_repo.count() == 30

    # The first 5 inserted keys (key_01 .. key_05) must be evicted
    for i in range(1, 6):
        assert cache_repo.get(f"key_{i:02d}") is None

    # Keys key_06 through key_35 must exist
    for i in range(6, 36):
        assert cache_repo.get(f"key_{i:02d}") is not None


def test_key_update_refreshes_content_and_timestamp(db_session):
    """Test updating an existing key refreshes output_json and does not evict other entries."""
    cache_repo = LocalCacheRepository(db_session, max_capacity=30)

    # Fill cache up to capacity (30 items)
    for i in range(1, 31):
        cache_repo.put({"key": f"key_{i}", "output_json": f'{{"val": {i}}}'})

    assert cache_repo.count() == 30

    # Update key_1 (existing key)
    updated_res = cache_repo.put({"key": "key_1", "output_json": '{"val": "updated"}'})
    assert updated_res["output_json"] == '{"val": "updated"}'

    # Count must remain 30 and no entries should be evicted
    assert cache_repo.count() == 30
    for i in range(1, 31):
        assert cache_repo.get(f"key_{i}") is not None

    # Content of key_1 is updated
    assert cache_repo.get("key_1")["output_json"] == '{"val": "updated"}'


def test_complete_data_isolation(db_session):
    """
    Test complete data isolation:
    Calling cache_repo.clear() MUST NEVER delete or touch history or favorites records.
    """
    history_repo = LocalHistoryRepository(db_session)
    cache_repo = LocalCacheRepository(db_session)

    # Create history & favorite records
    history_item = history_repo.save_and_favorite({
        "input": "Important history item",
        "mode": "reading",
        "result_json": '{"translation": "重要歷史項目"}',
    })

    # Create cache entries
    cache_repo.put({"key": "cache_1", "output_json": "{}"})
    cache_repo.put({"key": "cache_2", "output_json": "{}"})

    assert history_repo.get_by_id(history_item["id"]) is not None
    assert cache_repo.count() == 2

    # Clear ONLY cache
    cache_repo.clear()

    # Cache table is cleared
    assert cache_repo.count() == 0

    # History & Favorite tables remain completely intact!
    retrieved_history = history_repo.get_by_id(history_item["id"])
    assert retrieved_history is not None
    assert retrieved_history["is_favorite"] is True
    assert db_session.query(HistoryModel).count() == 1
    assert db_session.query(FavoriteModel).count() == 1


def test_cache_validation_errors(db_session):
    """Test validation errors on empty or whitespace keys and output_json."""
    cache_repo = LocalCacheRepository(db_session)

    with pytest.raises(ValidationError):
        cache_repo.put({"key": "   ", "output_json": "{}"})

    with pytest.raises(ValidationError):
        cache_repo.put({"key": "valid_key", "output_json": "   "})
