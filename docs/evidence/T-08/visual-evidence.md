# T-08 Visual Evidence

## Artifact

- Formal path：`docs/evidence/T-08/reading-mode.png`
- Source path：`D:\GitHub\workspace\lingolens-audit-t08\test\visual\reading-mode.png`
- File size：`29,900` bytes
- SHA-256：`a0ab1a3f5710c25976b9bb589b63201c93d0ded20336032132fa5b74a4a08404`

## Generation command

Temporary disposable-only harness command：

`flutter test --update-goldens test/visual/reading_mode_screenshot_test.dart`

- Working directory：`D:\GitHub\workspace\lingolens-audit-t08`
- Exit code：`0`
- Result：`PASS`
- Relevant stdout：`captures the T-08 Reading mode evidence image`；`All tests passed!`
- Generated artifact：`test/visual/reading-mode.png`
- Harness status：只存在於 disposable clone，未加入 formal source；完成後已移除 harness source 與 golden 暫存檔

Artifact 以 binary copy 複製至 formal path，未透過文字讀取／重新輸出；複製後 SHA-256 相同。已使用 `view_image` 檢查，確認 Translation、quick actions、五個 Reading sections、session actions、Feedback panel 與長版面均可見。

Limitation：Flutter test backend 的字型渲染可能與 Windows／macOS production font 不同；此 PNG 是 hierarchy／layout evidence，不宣稱 production OS font parity。
