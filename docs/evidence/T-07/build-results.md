# T-07 Build Results

## Windows build

### Command

```text
flutter build windows
```

- Working directory：`D:\GitHub\workspace\lingolens-audit\T-07-working`
- Exit code：`1`
- Result：`BLOCKED`
- Diagnostic：Flutter 找不到 `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe`。
- Classification：environment blocker；不是以 build failure 推論程式碼 failure。

## macOS build

- Result：`NOT_RUN`
- Limitation：目前 host 為 Windows；不宣稱 macOS verification。
