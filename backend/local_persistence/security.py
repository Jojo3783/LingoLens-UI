import logging
import os
from pathlib import Path
from typing import Optional

from cryptography.fernet import Fernet, InvalidToken

logger = logging.getLogger(__name__)


class SecretKeyManager:
    """
    Manages local AES encryption master key using cryptography.fernet.
    Resolves master key from environment variable or local key file (.lingolens_secret.key).
    """

    DEFAULT_KEY_FILE = ".lingolens_secret.key"

    def __init__(self, key_file_path: Optional[Path] = None):
        self.key_file_path = key_file_path or Path(self.DEFAULT_KEY_FILE)
        self._key = self._resolve_or_create_key()
        self._fernet = Fernet(self._key)

    def _resolve_or_create_key(self) -> bytes:
        """Resolves key from env var, key file, or generates a new key."""
        # 1. Environment Variable
        env_key = os.getenv("LINGOLENS_SECRET_KEY")
        if env_key:
            try:
                key_bytes = env_key.strip().encode("utf-8")
                # Test validity with Fernet
                Fernet(key_bytes)
                return key_bytes
            except Exception as e:
                logger.warning(f"Invalid LINGOLENS_SECRET_KEY in environment: {e}")

        # 2. Key File
        if self.key_file_path.exists():
            try:
                key_bytes = self.key_file_path.read_bytes().strip()
                Fernet(key_bytes)
                return key_bytes
            except Exception as e:
                logger.warning(f"Failed to read existing secret key file: {e}")

        # 3. Generate New Key
        new_key = Fernet.generate_key()
        try:
            self.key_file_path.parent.mkdir(parents=True, exist_ok=True)
            self.key_file_path.write_bytes(new_key)
            if hasattr(os, "chmod"):
                try:
                    os.chmod(self.key_file_path, 0o600)
                except Exception:
                    pass
        except Exception as e:
            logger.warning(f"Could not persist secret key file to disk: {e}")

        return new_key

    def encrypt_api_key(self, plain_key: str) -> str:
        """
        Encrypts a plain-text API key into a Base64 ciphertext string.
        Returns empty string if plain_key is empty or whitespace.
        """
        if not plain_key or not plain_key.strip():
            return ""

        trimmed = plain_key.strip()
        encrypted_bytes = self._fernet.encrypt(trimmed.encode("utf-8"))
        return encrypted_bytes.decode("utf-8")

    def decrypt_api_key(self, cipher_text: str) -> Optional[str]:
        """
        Decrypts Base64 ciphertext back to plain-text API key.
        Returns None if cipher_text is empty or decryption fails.
        """
        if not cipher_text or not cipher_text.strip():
            return None

        try:
            decrypted_bytes = self._fernet.decrypt(cipher_text.strip().encode("utf-8"))
            return decrypted_bytes.decode("utf-8")
        except InvalidToken:
            logger.warning("Decryption failed: Invalid secret key or corrupted ciphertext.")
            return None
        except Exception as e:
            logger.warning(f"Unexpected error during API key decryption: {e}")
            return None
