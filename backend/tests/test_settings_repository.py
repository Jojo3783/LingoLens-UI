import json
from pathlib import Path
import pytest
from pydantic import ValidationError

from local_persistence.security import SecretKeyManager
from local_persistence.settings_repository import LocalSettingsRepository
from local_persistence.settings_schemas import SettingsUpdateDTO, SettingsModel


@pytest.fixture
def secret_manager(tmp_path: Path) -> SecretKeyManager:
    key_file = tmp_path / "test_secret.key"
    return SecretKeyManager(key_file_path=key_file)


@pytest.fixture
def settings_repo(tmp_path: Path, secret_manager: SecretKeyManager) -> LocalSettingsRepository:
    settings_file = tmp_path / "settings.json"
    return LocalSettingsRepository(settings_path=settings_file, secret_manager=secret_manager)


def test_default_initialization_when_file_not_found(settings_repo: LocalSettingsRepository):
    """Test default settings are loaded when settings.json does not exist."""
    model = settings_repo.load_settings()

    assert model.selected_provider == "fake"
    assert model.openai_model == "gpt-5-mini"
    assert model.history_writes_enabled is True
    assert model.encrypted_api_key is None
    assert settings_repo.get_active_api_key() is None


def test_corrupted_json_falls_back_to_defaults(settings_repo: LocalSettingsRepository, tmp_path: Path):
    """Test corrupted JSON automatically falls back to default settings without crashing."""
    settings_file = settings_repo.settings_path
    settings_file.write_text("invalid json {{{ content", encoding="utf-8")

    model = settings_repo.load_settings()
    assert model.selected_provider == "fake"
    assert model.openai_model == "gpt-5-mini"


def test_secret_key_manager_encryption_decryption(secret_manager: SecretKeyManager):
    """Test SecretKeyManager encrypts and decrypts plain-text keys correctly."""
    plain_key = "sk-proj-1234567890abcdefghijklmn"

    ciphertext = secret_manager.encrypt_api_key(plain_key)
    assert ciphertext != plain_key
    assert len(ciphertext) > 0

    decrypted = secret_manager.decrypt_api_key(ciphertext)
    assert decrypted == plain_key


def test_secret_key_manager_handles_empty_key(secret_manager: SecretKeyManager):
    """Test SecretKeyManager returns empty/None for empty strings."""
    assert secret_manager.encrypt_api_key("") == ""
    assert secret_manager.encrypt_api_key("   ") == ""
    assert secret_manager.decrypt_api_key("") is None
    assert secret_manager.decrypt_api_key(None) is None


def test_update_settings_and_atomic_file_write(settings_repo: LocalSettingsRepository):
    """Test updating settings persists to JSON file atomically."""
    plain_key = "sk-proj-testkey9999"
    update_dto = SettingsUpdateDTO(
        selected_provider="openai_responses",
        openai_model="gpt-4o-mini",
        history_writes_enabled=False,
        openai_api_key=plain_key,
    )

    response_dto = settings_repo.update_settings(update_dto)

    assert response_dto.selected_provider == "openai_responses"
    assert response_dto.openai_model == "gpt-4o-mini"
    assert response_dto.history_writes_enabled is False
    assert response_dto.has_api_key is True
    assert response_dto.masked_api_key == "sk-...9999"

    # Verify JSON on disk does NOT contain plain text key
    file_content = settings_repo.settings_path.read_text(encoding="utf-8")
    assert plain_key not in file_content
    raw_json = json.loads(file_content)
    assert raw_json["selected_provider"] == "openai_responses"
    assert raw_json["encrypted_api_key"] is not None

    # Verify temporary file was cleaned up
    tmp_file = settings_repo.settings_path.with_suffix(".tmp")
    assert not tmp_file.exists()

    # Verify active API key decrypted in memory
    assert settings_repo.get_active_api_key() == plain_key


def test_clear_api_key(settings_repo: LocalSettingsRepository):
    """Test clear_api_key removes the encrypted key from disk and memory."""
    plain_key = "sk-proj-tempkey1234"
    settings_repo.update_settings(SettingsUpdateDTO(openai_api_key=plain_key))
    assert settings_repo.get_active_api_key() == plain_key

    settings_repo.clear_api_key()

    assert settings_repo.get_active_api_key() is None
    model = settings_repo.load_settings()
    assert model.encrypted_api_key is None


def test_validation_rules():
    """Test validation errors for invalid fields."""
    with pytest.raises(ValidationError):
        SettingsModel(openai_model="a" * 81)

    with pytest.raises(ValidationError):
        SettingsUpdateDTO(openai_model="   ")

    with pytest.raises(ValidationError):
        SettingsUpdateDTO(selected_provider="invalid_provider")
