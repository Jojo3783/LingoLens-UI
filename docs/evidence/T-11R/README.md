# T-11R Evidence

本目錄記錄既有 PR #14 的 T-11R remediation verification。所有測試均使用
controlled seam，不執行 live OpenAI API；Flutter dependency／build state 均在
disposable clone 產生，不寫入正式 Repository。

- [preflight.md](preflight.md)：immutable baseline 與 PR metadata。
- [cancellation-and-byte-cap.md](cancellation-and-byte-cap.md)：cancellation、
  overall deadline 與 response body limit。
- [observability.md](observability.md)：metric boundary、terminal event ordering、
  privacy boundary 與 provider-neutral UI。
- [verification.md](verification.md)：完整 command evidence 與結果。
- [delivery.md](delivery.md)：commit、push、PR #14 與 archive integrity。
