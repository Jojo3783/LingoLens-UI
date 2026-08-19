from pathlib import Path
from local_persistence.database import SessionLocal
from local_persistence.repositories.history_repository import LocalHistoryRepository
from local_persistence.repositories.favorite_repository import LocalFavoriteRepository
from local_persistence.repositories.cache_repository import LocalCacheRepository
from local_persistence.settings_repository import LocalSettingsRepository
from local_persistence.security import SecretKeyManager
from local_persistence.settings_schemas import SettingsUpdateDTO

def run_manual_test():
    db = SessionLocal()
    try:
        # 1. 測試 History & Favorite 持久化
        print("=== 1. 測試 History & Favorite ===")
        history_repo = LocalHistoryRepository(db)
        fav_repo = LocalFavoriteRepository(db)
        
        # 建立一筆歷史並加到最愛
        saved_rec = history_repo.save_and_favorite({
            "input": "Bonjour le monde",
            "mode": "reading",
            "result_json": '{"translation": "你好，世界"}'
        })
        print(f"已寫入歷史紀錄 ID: {saved_rec['id']}, is_favorite: {saved_rec['is_favorite']}")

        # 2. 測試 Cache 持久化
        print("\n=== 2. 測試 Analysis Cache ===")
        cache_repo = LocalCacheRepository(db, max_capacity=30)
        cache_data = {
            "key": "hash_manual_test_reading",
            "output_json": '{"cached_result": "測試快取資料"}'
        }
        saved_cache = cache_repo.put(cache_data)
        print(f"已寫入快取 Key: {saved_cache['key']}, 目前快取筆數: {cache_repo.count()}")

        # 3. 測試 Settings JSON 持久化與金鑰加密
        print("\n=== 3. 測試 Settings JSON & API Key 加密 ===")
        secret_mgr = SecretKeyManager()
        settings_repo = LocalSettingsRepository(
            settings_path=Path("./settings.json"),
            secret_manager=secret_mgr
        )
        update_dto = SettingsUpdateDTO(
            selected_provider="openai_responses",
            openai_model="gpt-4o-mini",
            history_writes_enabled=True,
            openai_api_key="sk-proj-manualtestsecretkey8888"
        )
        res_dto = settings_repo.update_settings(update_dto)
        print(f"設定已更新: {res_dto.model_dump()}")

        print("\n🎉 手動資料寫入完成！現在可以打開 DB Browser 和 settings.json 查看成果！")

    finally:
        db.close()

if __name__ == "__main__":
    run_manual_test()