# T-12R2 Provider Boundary Evidence

## Startup hydration

`LingoLensApp` 先等待 `ProviderSettingsController.initialize()` 完成，再建立 analysis-ready shell。Injected fake secure storage 測試覆蓋：

- fresh install 維持 deterministic Fake Provider；
- persisted Fake preference 維持 Fake；
- persisted OpenAI preference、model 與 credential 在 shell ready 前完成 runtime composition；
- persisted OpenAI preference 但 credential 缺失時仍維持 OpenAI-selected，回傳 configuration-required，不靜默切回 Fake；
- secure storage read failure 顯示 typed error，Fake 與 manual input 仍可使用。

## Secret boundary

- 移除 `ProviderSettingsController.credentialSource` public getter。
- `ProviderRuntimeCoordinator` 是 Application-owned boundary，只有它可由 controller private state 組成 Provider。
- Public profile、status、debug string、Semantics 與 Widget 不回傳 raw credential 或 fragment。
- persistence test 只直接檢查 fake `SecureCredentialStore` adapter，不透過 public UI state 讀 secret。

## Secure storage and Save and Apply

- read／write／delete failure 皆映射為 typed `secureStorageError` 或 typed failure，不留下 unhandled startup Future。
- Provider preference persistence failure 不先更新 selected runtime。
- `儲存並套用` 同時驗證及保存目前 model 與新輸入 API key；model 不需 Enter 才保存。
- partial persistence failure 會嘗試 rollback，UI 不宣稱 runtime 已完整套用。
- 只有成功後清除 API-key editing field。

## Evidence

Final candidate focused suite：23 tests passed；full suite：150 tests passed；未使用 real API key，未執行 live OpenAI API。詳見 [verification.md](verification.md)。
