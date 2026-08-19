# T-06R Verification Results

## Verification environment

- Disposable clone：D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
- Frozen commit：69407b6（正式 Repository remediation code／test commit）
- Host：Windows
- Flutter：3.41.5
- Dart：3.11.3
- Git：2.53.0.windows.1
- Start／End timestamps：目前 shell receipt 未捕捉 timestamp，未捏造；command、exit code 與 relevant output 如下。

## Command receipts

### Dependency restore

Task: T-06R
Command: flutter --suppress-analytics pub get
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: Got dependencies!; 4 packages have newer versions incompatible with dependency constraints.
Relevant stderr: empty
Generated artifacts: disposable clone only

### Format

Task: T-06R
Command: dart --suppress-analytics format --output=none --set-exit-if-changed .
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: Formatted 17 files (0 changed) in 0.16 seconds.
Relevant stderr: empty
Generated artifacts: none

### Analyze

Task: T-06R
Command: flutter --suppress-analytics analyze
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: No issues found! (ran in 2.2s)
Relevant stderr: empty
Generated artifacts: disposable clone only

### Focused tests

Task: T-06R
Command: flutter --suppress-analytics test test/domain/analysis_models_test.dart test/application/analysis_input_boundary_test.dart test/application/error_contract_test.dart test/application/persistence_controller_test.dart
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: 00:00 +51: All tests passed!
Relevant stderr: empty
Generated artifacts: disposable clone only

### Complete tests

Task: T-06R
Command: flutter --suppress-analytics test
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: 00:01 +65: All tests passed!
Relevant stderr: empty
Generated artifacts: disposable clone only

### Diff check and clone status

Task: T-06R
Command: git diff --check && git status --short --branch
Working directory: D:\GitHub\workspace\lingolens-audit\T-06R-69407b6
Exit code: 0
Result: PASS
Relevant stdout: ## feat/t06-domain-schema-errors...origin/feat/t06-domain-schema-errors
Relevant stderr: empty
Generated artifacts: none

## Limitations

- flutter build windows 的結果另記於 build-results.md。
- macOS build／runtime：NOT_RUN，目前 host 為 Windows。
- 沒有宣稱任何未執行的 CI、macOS 或 runtime result。
