# T-06 Build Evidence

## Windows

- Command：`flutter --suppress-analytics build windows`
- Working directory：`D:\GitHub\workspace\lingolens-audit\T-06-final-de4da2c`
- Exit code：`1`
- Result：`BLOCKED`
- Relevant stderr：`ProcessException: Failed to find "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" in the search path.`
- Environment evidence：Visual Studio Community 2022 `17.12.0`、Windows SDK `10.0.22621.0` detected；CMake executable missing
- Generated artifacts：Flutter crash log created in disposable clone and removed；正式 Repository 未產生 build artifact
- Reason：環境缺少 CMake，不是 T-06 code failure

## macOS

- Command：macOS build／runtime
- Working directory：N/A
- Exit code：N/A
- Result：`NOT_RUN`
- Reason：目前 host 為 Windows；不得宣稱 macOS verification
