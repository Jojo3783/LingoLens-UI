# T-06 Limitations

- `docs/PRODUCT_DEFINITION.md` 不存在；本輪使用現有 `docs/PRODUCT_SCOPE.md`，未捏造缺失文件。
- `docs/decisions/README.md` 與 individual ADR Approval 狀態不一致；本輪依 accepted ADR 文件本身與 source-of-truth precedence，未修改 ADR。
- Windows build 受 CMake executable 缺失阻擋；這不是程式碼失敗。
- macOS build／runtime 未執行，因目前 host 為 Windows。
- T-06 不包含 T-07 mode selection、real provider、progressive results、native platform integration 或 durable production persistence。
- T-06 的 input boundary tests 沒有 integrated AnalysisController→PersistenceController workflow；它們只驗證 input validation 與 provider invocation boundary。T-06R 已移除原本不成立的 History／Cache assertion。
