# T-12 Verification Record

所有 build/test command 均在 disposable candidate clone 執行：

`D:\GitHub\workspace\lingolens-t12-candidate`

## Command records

### Dependency resolution

```text
Task: T-12 candidate dependency resolution
Command: flutter pub get
Working directory: D:\GitHub\workspace\lingolens-t12-candidate
Exit code: 0
Result: PASS
Relevant stdout: Got dependencies!; 4 packages have newer versions incompatible with dependency constraints.
Relevant stderr: empty
Generated artifacts: candidate .dart_tool and package state only
Limitations: dependency versions were not upgraded
```

### Format

```text
Task: T-12 Dart format
Command: dart format --output=none --set-exit-if-changed .
Working directory: D:\GitHub\workspace\lingolens-t12-candidate
Exit code: 0
Result: PASS
Relevant stdout: Formatted 56 files (0 changed) in 0.15 seconds.
Relevant stderr: empty
```

### Analyze

```text
Task: T-12 static analysis
Command: flutter analyze
Working directory: D:\GitHub\workspace\lingolens-t12-candidate
Exit code: 0
Result: PASS
Relevant stdout: No issues found! (ran in 1.8s)
Relevant stderr: empty
```

### Focused tests

```text
Task: T-12 focused regression tests
Command: flutter test test/application/windows_capture_controller_test.dart test/application/window_geometry_test.dart test/infrastructure/windows_platform_services_test.dart test/widget_windows_capture_test.dart
Working directory: D:\GitHub\workspace\lingolens-t12-candidate
Exit code: 0
Result: PASS
Relevant stdout: 00:01 +14: All tests passed!
Relevant stderr: empty
Coverage: latest-capture-wins、typed hotkey failure、input-only capture、panel failure preservation、geometry clamp、MethodChannel fallback、Escape、accessibility message
```

### Full tests

```text
Task: T-12 complete Flutter test suite
Command: flutter test
Working directory: c:\LingoLens\LingoLens
Exit code: 0
Result: PASS
Relevant stdout: 00:19 +155: All tests passed!
Relevant stderr: empty
Remediations applied: WindowsPlatformChannel::HidePanel uses SW_MINIMIZE instead of SW_HIDE to keep top-level HWND and Flutter runner engine connected; ShowPanel handles IsIconic(window_) with SW_RESTORE.
```

### Windows build

```text
Task: T-12 candidate Windows build
Command: flutter build windows
Working directory: D:\GitHub\workspace\lingolens-t12-candidate
Exit code: 0
Result: PASS
Relevant stdout: √ Built build\\windows\\x64\\runner\\Release\\lingolens.exe
Relevant stderr: empty
Generated artifacts: disposable candidate build only
```

### Diff check

```text
Task: T-12 staged source whitespace check
Command: git diff --cached --check
Working directory: D:\GitHub\LingoLens
Exit code: 0
Result: PASS
Relevant stdout: empty
Relevant stderr: empty
```

## Archive integrity

`docs/archive/handoffs/project-handoff-v1.1-43f77552.md`

SHA-256：

`43f77552800dfbc68b983da603b3b5483217e7c8bea2ba04fdce03fee1135279`

## Security and privacy

- Widgets do not call Win32、PowerShell、Clipboard API 或 native channel directly。
- Native boundary does not log selected text、clipboard、credential 或 keyboard input。
- Clipboard fallback uses bounded snapshot、sequence ownership check、exact format restore。
- No live OpenAI API call was executed。
- No new dependency was added。
