from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy import create_engine, event, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker
from pydantic import ValidationError

from local_persistence.database import Base
from local_persistence.models import HistoryModel, FavoriteModel
from local_persistence.repositories.history_repository import LocalHistoryRepository


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


def test_save_and_read_history(db_session):
    """Test saving a history record and reading it back."""
    repo = LocalHistoryRepository(db_session)
    sample_data = {
        "input": "Hello world",
        "mode": "reading",
        "result_json": '{"translation": "你好世界"}',
    }

    saved = repo.save(sample_data)
    assert saved["id"] is not None
    assert saved["input"] == "Hello world"
    assert saved["mode"] == "reading"
    assert saved["result_json"] == '{"translation": "你好世界"}'
    assert saved["is_favorite"] is False

    # Read back from DB
    retrieved = repo.get_by_id(saved["id"])
    assert retrieved is not None
    assert retrieved["id"] == saved["id"]
    assert retrieved["input"] == "Hello world"


def test_unsaved_results_not_in_db(db_session):
    """Test that unsaved results are not present in the DB."""
    repo = LocalHistoryRepository(db_session)

    # Empty DB checks
    visible = repo.list_visible(limit=20)
    assert len(visible) == 0

    retrieved = repo.get_by_id("non-existent-uuid")
    assert retrieved is None

    # Count in tables is 0
    assert db_session.query(HistoryModel).count() == 0
    assert db_session.query(FavoriteModel).count() == 0


def test_save_and_favorite_atomic_success(db_session):
    """Test save_and_favorite creates both History and Favorite records atomically."""
    repo = LocalHistoryRepository(db_session)
    sample_data = {
        "input": "Important sentence",
        "mode": "expression",
        "result_json": '{"analysis": "formal"}',
    }

    result = repo.save_and_favorite(sample_data)
    assert result["id"] is not None
    assert result["is_favorite"] is True

    # Verify both records exist in DB
    history_in_db = db_session.query(HistoryModel).filter(HistoryModel.id == result["id"]).first()
    favorite_in_db = db_session.query(FavoriteModel).filter(FavoriteModel.history_id == result["id"]).first()

    assert history_in_db is not None
    assert favorite_in_db is not None


def test_save_and_favorite_atomic_rollback(db_session):
    """Test that failure in save_and_favorite rolls back transaction completely."""
    repo = LocalHistoryRepository(db_session)

    # Invalid input (empty string after strip) triggers ValidationError
    invalid_data = {
        "input": "   ",
        "mode": "reading",
        "result_json": "{}",
    }

    with pytest.raises(ValidationError):
        repo.save_and_favorite(invalid_data)

    # Verify nothing was saved to DB
    assert db_session.query(HistoryModel).count() == 0
    assert db_session.query(FavoriteModel).count() == 0


def test_list_visible_sorting_behavior(db_session):
    """
    Test list_visible sorting rule (F-001):
    Favorited items appear first, followed by created_at DESC.
    """
    repo = LocalHistoryRepository(db_session)
    base_time = datetime.now(timezone.utc)

    # Create 5 records with specific timestamps
    # Record 1: 10 minutes ago, NOT favorited
    rec1 = repo.save({
        "input": "Rec 1", "mode": "reading", "result_json": "{}"
    })
    db_session.query(HistoryModel).filter_by(id=rec1["id"]).update(
        {"created_at": base_time - timedelta(minutes=10)}
    )

    # Record 2: 5 minutes ago, NOT favorited
    rec2 = repo.save({
        "input": "Rec 2", "mode": "reading", "result_json": "{}"
    })
    db_session.query(HistoryModel).filter_by(id=rec2["id"]).update(
        {"created_at": base_time - timedelta(minutes=5)}
    )

    # Record 3: 1 minute ago, NOT favorited
    rec3 = repo.save({
        "input": "Rec 3", "mode": "reading", "result_json": "{}"
    })
    db_session.query(HistoryModel).filter_by(id=rec3["id"]).update(
        {"created_at": base_time - timedelta(minutes=1)}
    )

    # Record 4: 8 minutes ago, FAVORITED
    rec4 = repo.save_and_favorite({
        "input": "Rec 4 Fav", "mode": "expression", "result_json": "{}"
    })
    db_session.query(HistoryModel).filter_by(id=rec4["id"]).update(
        {"created_at": base_time - timedelta(minutes=8)}
    )

    # Record 5: 3 minutes ago, FAVORITED
    rec5 = repo.save_and_favorite({
        "input": "Rec 5 Fav", "mode": "expression", "result_json": "{}"
    })
    db_session.query(HistoryModel).filter_by(id=rec5["id"]).update(
        {"created_at": base_time - timedelta(minutes=3)}
    )

    db_session.commit()

    visible = repo.list_visible(limit=20)
    assert len(visible) == 5

    # Expected order:
    # 1. Rec 5 (Fav, 3 min ago)
    # 2. Rec 4 (Fav, 8 min ago)
    # 3. Rec 3 (Not fav, 1 min ago)
    # 4. Rec 2 (Not fav, 5 min ago)
    # 5. Rec 1 (Not fav, 10 min ago)
    assert visible[0]["id"] == rec5["id"]
    assert visible[0]["is_favorite"] is True

    assert visible[1]["id"] == rec4["id"]
    assert visible[1]["is_favorite"] is True

    assert visible[2]["id"] == rec3["id"]
    assert visible[2]["is_favorite"] is False

    assert visible[3]["id"] == rec2["id"]
    assert visible[3]["is_favorite"] is False

    assert visible[4]["id"] == rec1["id"]
    assert visible[4]["is_favorite"] is False


def test_list_visible_limit_does_not_auto_delete(db_session):
    """
    Test Data Retention Rule (F-001):
    Reaching the 20-record display limit MUST NEVER auto-delete records from DB.
    """
    repo = LocalHistoryRepository(db_session)

    # Insert 25 records
    for i in range(25):
        repo.save({
            "input": f"Sentence {i}",
            "mode": "reading",
            "result_json": "{}",
        })

    # Query with limit 20
    visible = repo.list_visible(limit=20)
    assert len(visible) == 20

    # Total DB count must still be 25!
    total_db_count = db_session.query(HistoryModel).count()
    assert total_db_count == 25


def test_delete_history_cascades_favorite(db_session):
    """Test deleting a History record cascades deletion to favorites."""
    repo = LocalHistoryRepository(db_session)

    fav_rec = repo.save_and_favorite({
        "input": "To be deleted",
        "mode": "reading",
        "result_json": "{}",
    })
    rec_id = fav_rec["id"]

    # Verify both records exist
    assert db_session.query(HistoryModel).filter_by(id=rec_id).count() == 1
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 1

    # Delete history record
    repo.delete(rec_id)

    # Verify both history and favorite records were deleted
    assert db_session.query(HistoryModel).filter_by(id=rec_id).count() == 0
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 0


def test_input_validation(db_session):
    """Test validation rules on HistoryRecordCreate."""
    repo = LocalHistoryRepository(db_session)

    # Test > 2000 characters
    long_input = "a" * 2001
    with pytest.raises(ValidationError):
        repo.save({
            "input": long_input,
            "mode": "reading",
            "result_json": "{}",
        })

    # Test invalid mode
    with pytest.raises(ValidationError):
        repo.save({
            "input": "valid input",
            "mode": "invalid_mode",
            "result_json": "{}",
        })
