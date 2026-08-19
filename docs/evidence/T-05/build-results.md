# T-05 Build Evidence

Working directory：`D:\GitHub\LingoLens`

## Windows

Command：`flutter build windows`

- Exit code：`1`
- Result：`BLOCKED`
- Error：`ProcessException: Failed to find "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\Common7\\IDE\\CommonExtensions\\Microsoft\\CMake\\CMake\\bin\\cmake.exe"`
- Flutter detected Visual Studio Community 2022 `17.12.0` and Windows SDK `10.0.22621.0`, but the expected CMake executable path was missing.
- Flutter generated `flutter_01.log` during the failed attempt. The log was inspected and removed from the writable Repository; it is not committed.

## macOS

- Build：`NOT_RUN`
- Runtime：`NOT_RUN`
- Reason：The current verification host is Windows; no macOS/Xcode environment is available here.
