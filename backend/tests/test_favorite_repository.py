from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from local_persistence.database import Base
from local_persistence.models import HistoryModel, FavoriteModel
from local_persistence.repositories.history_repository import LocalHistoryRepository
from local_persistence.repositories.favorite_repository import LocalFavoriteRepository


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


def test_set_favorite_add_and_remove(db_session):
    """Test adding and removing favorites using LocalFavoriteRepository."""
    history_repo = LocalHistoryRepository(db_session)
    fav_repo = LocalFavoriteRepository(db_session)

    # Save a history record
    rec = history_repo.save({
        "input": "Test favorite sentence",
        "mode": "reading",
        "result_json": "{}",
    })
    rec_id = rec["id"]

    # Initial state: not favorited
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 0

    # Set favorite to True
    fav_repo.set_favorite(rec_id, True)
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 1

    # Idempotent check: setting favorite True again doesn't duplicate
    fav_repo.set_favorite(rec_id, True)
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 1


def test_unmark_favorite_leaves_history_intact(db_session):
    """
    Test F-001 requirement:
    Unmarking/removing a favorite MUST NOT delete the underlying History record.
    """
    history_repo = LocalHistoryRepository(db_session)
    fav_repo = LocalFavoriteRepository(db_session)

    # Create saved & favorited record
    rec = history_repo.save_and_favorite({
        "input": "Keep this history record",
        "mode": "expression",
        "result_json": "{}",
    })
    rec_id = rec["id"]

    assert db_session.query(HistoryModel).filter_by(id=rec_id).count() == 1
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 1

    # Unmark favorite
    fav_repo.set_favorite(rec_id, False)

    # Favorite entry is removed
    assert db_session.query(FavoriteModel).filter_by(history_id=rec_id).count() == 0

    # History record MUST still exist!
    history_in_db = db_session.query(HistoryModel).filter_by(id=rec_id).first()
    assert history_in_db is not None
    assert history_in_db.input == "Keep this history record"


def test_set_favorite_non_existent_history_raises_error(db_session):
    """Test that setting favorite on a non-existent history record raises ValueError."""
    fav_repo = LocalFavoriteRepository(db_session)

    with pytest.raises(ValueError, match="does not exist"):
        fav_repo.set_favorite("non-existent-uuid", True)


def test_list_all_favorites(db_session):
    """Test list_all returns all favorited history records ordered by created_at DESC."""
    history_repo = LocalHistoryRepository(db_session)
    fav_repo = LocalFavoriteRepository(db_session)
    base_time = datetime.now(timezone.utc)

    # Create 3 history records
    rec1 = history_repo.save({"input": "Sentence 1", "mode": "reading", "result_json": "{}"})
    rec2 = history_repo.save({"input": "Sentence 2", "mode": "reading", "result_json": "{}"})
    rec3 = history_repo.save({"input": "Sentence 3", "mode": "reading", "result_json": "{}"})

    # Favorite rec1 and rec3 with specific timestamps
    fav_repo.set_favorite(rec1["id"], True)
    fav_repo.set_favorite(rec3["id"], True)

    db_session.query(FavoriteModel).filter_by(history_id=rec1["id"]).update(
        {"created_at": base_time - timedelta(minutes=5)}
    )
    db_session.query(FavoriteModel).filter_by(history_id=rec3["id"]).update(
        {"created_at": base_time - timedelta(minutes=1)}
    )
    db_session.commit()

    all_favs = fav_repo.list_all()
    assert len(all_favs) == 2

    # Ordered by created_at DESC (rec3 created 1 min ago, rec1 created 5 min ago)
    assert all_favs[0]["id"] == rec3["id"]
    assert all_favs[0]["input"] == "Sentence 3"
    assert all_favs[0]["is_favorite"] is True

    assert all_favs[1]["id"] == rec1["id"]
    assert all_favs[1]["input"] == "Sentence 1"
    assert all_favs[1]["is_favorite"] is True
