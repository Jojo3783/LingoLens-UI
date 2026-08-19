# T-07 Limitations

- Automatic mode suggestion 是 deterministic interface implementation，預設永遠建議 `Reading`；不代表 real language detection。
- Listen 是 `FakeSpeechAdapter`，只記錄文字並提供 deterministic stop；不代表 real TTS。
- Save、Favorite、Feedback 只存在於本次 process 的 in-memory repositories；不代表 durable user data。
- Windows build 受 disposable clone 的 CMake executable environment blocker 影響。
- macOS build／runtime 尚未執行，因目前 host 為 Windows。
- T-08／T-09 expanded result fields、real provider、progressive result 與 native integrations 明確保留到後續授權。
