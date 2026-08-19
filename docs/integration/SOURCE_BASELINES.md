# T-02 Disposable Source Baselines

> Task: T-02 Disposable Source Baseline
> Status: READY_FOR_REVIEW
> Baseline timestamp: 2026-07-26T23:52:21+08:00 onward
> Scope: source metadata, disposable verification, and provenance only

## Baseline policy

本文件只記錄三個唯讀來源的 immutable Git metadata 與 Disposable Clone 對照。來源 Repository 位於 `D:\GitHub\temp`，未執行 Pull、Checkout、Reset、Clean、Commit、Dependency Restore、Build 或任何寫入操作。所有會產生工具狀態的命令均在 `D:\GitHub\workspace\lingolens-audit` 執行。

## Source inventory

| Role | Source Path | Remote | Branch | HEAD | Latest commit | Working Tree | Tracked files | Framework／Project type | License |
|---|---|---|---|---|---|---|---:|---|---|
| Jimmy Functional Reference | `D:\GitHub\temp\Prototype` | `https://github.com/j-neyrox/LingoLens` | `main` | `40e8d70e8e9bf336a2f66cf811736061831c2964` | `40e8d70 Fix favorites and history views (#2)` | clean | 92 | Swift／macOS Xcode project；`LingoLens.xcodeproj` | 未找到標準 License file |
| Joe Flutter Module Donor | `D:\GitHub\temp\Merged Model 1` | `https://github.com/Jojo3783/MVP-flutter-LingoLens` | `main` | `76a3826ce69827456b7c305018b629f1c22f4bd6` | `76a3826 MVP flutter code` | clean | 71 | Flutter app；實際 root 為 `FlutterVersion` | 未找到標準 License file |
| Ethan Flutter Base Candidate | `D:\GitHub\temp\Merged Model 2` | `https://github.com/FUNDAI/Lingolens_flutter_test` | `main` | `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | `df4f542 Enhance README with Codex CLI setup and project steps` | clean | 153 | Flutter app；Repository root 含 `lib`、`test`、`windows`、`macos` | 未找到標準 License file |

來源 Top-level inventory 與完整 freeze metadata 收錄於 `docs/evidence/T-02/metadata.txt`。來源在 baseline 前後均為 clean，且 HEAD 未改變。

## Manifest inventory

### Prototype

- No `pubspec.yaml`。
- No `Package.swift`。
- Xcode project: `LingoLens.xcodeproj`。
- 此來源不適用 Flutter baseline；Windows host 不執行 macOS/Xcode build。

### Merged Model 1

- App root: `D:\GitHub\temp\Merged Model 1\FlutterVersion`。
- Manifest: `FlutterVersion/pubspec.yaml`。
- Lockfile: `FlutterVersion/pubspec.lock`。
- Platforms: `macos`、`windows` 等 Flutter platform directories。
- Script observed: `FlutterVersion/debug_windows.ps1`。此為人工 debugging script，未自動執行。
- 未找到 `git:` 或 `path:` dependency declaration。

### Merged Model 2

- App root: `D:\GitHub\temp\Merged Model 2`。
- Manifest: `pubspec.yaml`。
- Lockfile: `pubspec.lock`。
- Platforms: `windows`、`macos`、`android`、`ios`。
- 未找到 `git:` 或 `path:` dependency declaration。
- `README.md` mentions `dart run build_runner build --delete-conflicting-outputs`；T-02 未執行 code generation。

## Disposable Clone mapping

| Source | Disposable Clone | Source HEAD | Clone HEAD | Clone status after baseline |
|---|---|---|---|---|
| `D:\GitHub\temp\Prototype` | `D:\GitHub\workspace\lingolens-audit\prototype` | `40e8d70e9e9bf336a2f66cf811736061831c2964` | `40e8d70e9e9bf336a2f66cf811736061831c2964` | clean |
| `D:\GitHub\temp\Merged Model 1` | `D:\GitHub\workspace\lingolens-audit\merged-model-1` | `76a3826ce69827456b7c305018b629f1c22f4bd6` | `76a3826ce69827456b7c305018b629f1c22f4bd6` | generated Flutter files modified |
| `D:\GitHub\temp\Merged Model 2` | `D:\GitHub\workspace\lingolens-audit\merged-model-2` | `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | `df4f5424e8abfedc52f941c8c5c2f1a9463e8aac` | generated Flutter files modified |

Clone 產生的修改僅是 disposable tool output：`.dart_tool`、`build`、Flutter crash logs，以及由 `flutter pub get`／build tooling regenerated 的 Flutter plugin registrant files。它們不在官方 Repository，也未回寫來源。

## Provenance boundary

T-02 未複製 Production Code，未選定 base repository，未作 Architecture、ADR、dependency upgrade 或 application implementation 決策。此文件只提供後續審查可重現的來源與工具基線。
