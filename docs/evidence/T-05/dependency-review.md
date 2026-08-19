# T-05 Dependency and Safety Review

## Toolchain

| Tool | Observed version |
|---|---|
| Flutter | `3.41.5` |
| Dart | `3.11.3` |
| Git | `2.53.0` |

## Dependency Changes

- `flutter create --platforms=windows,macos --project-name lingolens .` completed with exit code `0` and wrote 52 generated files.
- `pubspec.yaml` retains only Flutter runtime dependency plus `flutter_test` and `flutter_lints` development dependencies.
- Generated `cupertino_icons` was removed because the T-05 UI does not use it.
- `flutter pub get` completed with exit code `0`.
- No Riverpod dependency was added. ADR-002 does not mandate Riverpod, and the T-05 implementation uses a framework-agnostic Application controller composed with Flutter built-in APIs.

## Boundary Review

- No real AI provider, HTTP client, provider SDK, CLI, process runner, model, or secret was added.
- No Drift, SQLite, Isar, durable history store, schema, or migration was added.
- No Windows or macOS native integration, hotkey, selected-text service, clipboard integration, floating-window service, TTS, PowerShell, AppleScript, or native plugin was added.
- No custom PowerShell, batch, shell, or build script was added. The only shell script found is generated Flutter environment output under `macos/Flutter/ephemeral/`.
- Donor repositories under `D:\GitHub\temp` were not modified, formatted, built, or copied.
