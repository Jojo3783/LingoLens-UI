# T-12R Dependency and Boundary Review

## Command record

Task: T-12R dependency review
Command: `git diff -- pubspec.yaml pubspec.lock macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements`
Working directory: `D:\\GitHub\\LingoLens`
Start time: `2026-07-29`
End time: `2026-07-29`
Exit code: `0`
Result: `PASS`
Relevant stdout: `flutter_secure_storage: ^10.3.1` was the only new runtime dependency；macOS entitlements contain empty `keychain-access-groups` arrays。
Relevant stderr: empty
Generated artifacts: none in Repository
Git status before: existing T-12R changes only
Git status after: unchanged
Limitations: dependency resolution and verification are recorded in `dart-verification.md`；no dependency was added to read-only sources。

## Boundary decisions

- No live OpenAI request or API key was used。
- No Codex CLI、local model、multi-account、failover、custom endpoint 或 schema v4 was added。
- `flutter_secure_storage` is used only through the `SecureCredentialStore` interface。
- No raw credential is kept in `ProviderProfile`；tests use the synthetic marker
  `synthetic-t12r-credential` only。
