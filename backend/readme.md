# LingoLens Backend Local Persistence Layer

本模組為 LingoLens 本地持久化資料存取層（Local Persistence Layer），基於 **SQLite + SQLAlchemy ORM + Alembic** 實作，並透過 **Pydantic v2** 進行資料模型校驗與 DTO 轉換[cite: 2]。

---

## 1. 模組功能概覽

| 模組名稱 | 儲存載體 | 核心特性與契約保證 |
|---|---|---|
| **History & Favorites** | SQLite (`history`, `favorites`) | 支援手動儲存分析紀錄、星號最愛切換，提供原子性交易（`save_and_favorite`），刪除 History 時自動 Cascade 清除關聯 Favorite。 |
| **Analysis Cache** | SQLite (`analysis_cache`) | 獨立快取 AI 分析結果，內建 **30 筆上限容量淘汰機制 (FIFO)**。支援獨立清空快取，與 History / Favorites 100% 隔離。 |
| **Settings Repository** | JSON (`settings.json`) | 儲存本機應用程式偏好設定。透過 `cryptography.fernet` 對 OpenAI API Key 進行 AES 加密儲存與對外安全遮蔽（Masking）[cite: 2]。 |

---

## 2. 環境安裝與資料庫遷移

### 步驟 1：安裝依賴套件
```bash
pip install -r requirements.txt
```

### 步驟 2：執行 Alembic 遷移（建立或升級資料庫 Schema）
```bash
alembic upgrade head
```
> 執行後將於本機建立 `lingolens.db` 並套用 `001_initial_schema` 與 `002_create_analysis_cache_table`。

---

## 3. 核心 API 呼叫範例

### A. 分析快取模組（`LocalCacheRepository`）
```python
from local_persistence.database import SessionLocal
from local_persistence.repositories import LocalCacheRepository

db = SessionLocal()
try:
    # 預設容量上限 30 筆
    cache_repo = LocalCacheRepository(db, max_capacity=30)

    # 1. 寫入快取（滿 30 筆時自動淘汰 created_at 最舊的一筆）
    cache_repo.put({
        "key": "reading:gpt-5-mini:Bonjour le monde",
        "output_json": '{"translation": "你好，世界"}'
    })

    # 2. 查詢快取（若存在回傳 dict，不存在回傳 None）
    cached = cache_repo.get("reading:gpt-5-mini:Bonjour le monde")
    if cached:
        print("快取命中:", cached["output_json"])

    # 3. 清空快取（僅清空 analysis_cache，絕不影響 History 與 Favorites）
    cache_repo.clear()
finally:
    db.close()
```

---

### B. 歷史紀錄與最愛模組（`LocalHistoryRepository`, `LocalFavoriteRepository`）
```python
from local_persistence.database import SessionLocal
from local_persistence.repositories import LocalHistoryRepository, LocalFavoriteRepository

db = SessionLocal()
try:
    history_repo = LocalHistoryRepository(db)
    fav_repo = LocalFavoriteRepository(db)

    # 1. 儲存並同時標記最愛（單一原子交易，任一步失敗自動 Rollback）
    record = history_repo.save_and_favorite({
        "input": "Hello world",
        "mode": "reading",
        "result_json": '{"translation": "你好，世界"}'
    })
    print(f"已儲存 ID: {record['id']}, is_favorite: {record['is_favorite']}")

    # 2. 切換最愛狀態（取消最愛僅移除關聯，歷史紀錄仍保留）
    fav_repo.set_favorite(record["id"], is_favorite=False)

    # 3. 讀取可見歷史清單（最多 20 筆，Favorite 優先置頂排序）
    visible_list = history_repo.list_visible(limit=20)

    # 4. 刪除單筆紀錄（自動 Cascade 移除對應 Favorite）
    history_repo.delete(record["id"])
finally:
    db.close()
```

---

### C. 本地設定與金鑰安全管理（`LocalSettingsRepository`）
```python
from pathlib import Path
from local_persistence.security import SecretKeyManager
from local_persistence.settings_repository import LocalSettingsRepository
from local_persistence.settings_schemas import SettingsUpdateDTO

# 初始化金鑰管理器（會自動讀取或生成 .lingolens_secret.key）
secret_mgr = SecretKeyManager()
settings_repo = LocalSettingsRepository(
    settings_path=Path("./settings.json"),
    secret_manager=secret_mgr
)

# 1. 更新設定（API Key 會經 AES 加密後原子寫入磁碟）
update_dto = SettingsUpdateDTO(
    selected_provider="openai_responses",
    openai_model="gpt-4o-mini",
    history_writes_enabled=True,
    openai_api_key="sk-proj-example-secret-key-123456"
)
response_dto = settings_repo.update_settings(update_dto)

# 2. 對外顯示安全資訊（API Key 已自動遮蔽為 sk-...3456）
print("選擇 Provider:", response_dto.selected_provider)
print("是否有金鑰:", response_dto.has_api_key)
print("遮蔽後的金鑰:", response_dto.masked_api_key)

# 3. 後端內部實際呼叫 API 時在記憶體解密取得明文
plain_api_key = settings_repo.get_active_api_key()
```

---

## 4. 驗證與測試流程

### 方式 A：手動端到端驗證（`manual_test.py`）
專案根目錄提供手動測試腳本 `manual_test.py`，用於一次性驗證實體 SQLite 資料庫寫入、快取淘汰與 `settings.json` 加密寫入[cite: 2]：

1. **執行手動測試腳本**：
   ```bash
   python manual_test.py
   ```
2. **驗證產物**：
   * 使用 **DB Browser for SQLite** 打開 `lingolens.db`，確認 `history`、`favorites` 與 `analysis_cache` 表中已成功寫入測試資料[cite: 2]。
   * 檢視根目錄產生的 `settings.json`，確認 `encrypted_api_key` 為 Fernet 加密後的 Base64 密文（非明文字串）[cite: 2]。
   * 確認本機產生之金鑰檔 `.lingolens_secret.key` 權限為 `0o600`。

---

### 方式 B：自動化單元測試（`pytest`）
本模組的所有 Repository 與資安邏輯皆具備完整的 `pytest` 測試覆蓋（使用 In-Memory SQLite）[cite: 2]：

```bash
pytest -v
```

測試涵蓋項目：
* `test_cache_repository.py`：快取寫入、30 筆上限容量自動淘汰、資料隔離（`clear()` 不影響 History/Favorites）與驗證。
* `test_history_repository.py`：History 儲存、原子性 `save_and_favorite` 與 Rollback、20 筆上限排序與非物理刪除規則、Cascade 刪除。
* `test_favorite_repository.py`：最愛切換與去重、取消最愛保留 History、不存在紀錄之錯誤處理。
* `test_settings_repository.py`：設定檔 JSON 損壞自動修復預設值、Fernet AES 加解密、設定原子性寫入與金鑰遮蔽。