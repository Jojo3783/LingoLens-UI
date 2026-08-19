# T-12 Environment Evidence

## Gate 0 baseline

- Required `origin/main` SHA：`10f2d3da98d1fdbdfd2e0abbb39d758a396a6183`
- Fresh baseline clone：`D:\GitHub\workspace\lingolens-t12-gate-10f2d3d-postrepair`
- Baseline commit：required SHA exactly
- `flutter pub get`：exit code `0`
- `flutter analyze`：exit code `0`，`No issues found!`
- `flutter test`：exit code `0`，`123` tests passed
- `flutter build windows`：exit code `0`，產出 `build\windows\x64\runner\Release\lingolens.exe`

## Repaired toolchain

- Visual Studio Community 2022：`17.14.37516.0`，complete、launchable、no reboot
- Required CMake：`3.31.6-msvc6`
- MSVC：`19.44.35228`
- MSBuild：`17.14.51.32402`
- Windows SDK：`10.0.22621.0` 與 `10.0.26100.0`
- Flutter：`3.41.5`
- Dart：`3.11.3`
- Visual Studio Build Tools 2026：保留且未修改

## Repair artifact boundary

原始 system inventory、setup logs、bootstrapper、installer cleanup evidence 與
manual screenshots 保留於：

`D:\GitHub\workspace\lingolens-t12-system-repair`

它們不屬於 LingoLens Repository，未加入 Git。
