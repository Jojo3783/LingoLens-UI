# T-05R Contract Test Evidence

Task：P1-01 ADR-003 contracts 與 P2 lifecycle tests

Command：

```text
flutter test test/application/analysis_controller_test.dart test/application/persistence_controller_test.dart
```

Working directory：`D:\GitHub\LingoLens`

Start time：`2026-07-28T01:06:50+08:00`

End time：`2026-07-28T01:06:54+08:00`

Exit code：`0`

Result：`PASS`

Relevant stdout：

```text
00:00 +0: loading D:/GitHub/LingoLens/test/application/analysis_controller_test.dart
00:00 +10: D:/GitHub/LingoLens/test/application/persistence_controller_test.dart: persistence areas remain logically isolated
00:00 +11: D:/GitHub/LingoLens/test/application/persistence_controller_test.dart: deleting history does not implicitly clear cache
00:00 +12: D:/GitHub/LingoLens/test/application/persistence_controller_test.dart: disabled history writes prevent new history records
00:00 +13: D:/GitHub/LingoLens/test/application/persistence_controller_test.dart: visible history limit is a non-destructive policy and protects favorites
00:00 +14: D:/GitHub/LingoLens/test/application/persistence_controller_test.dart: feedback content is attached only with explicit consent
00:00 +15: All tests passed!
```

Relevant stderr：相依套件解析只回報 4 個受 constraint 限制的較新版本；無測試錯誤。

Generated artifacts：無。

Git status before：`fix/t05r-remediation`，本輪預期修改存在。

Git status after：與 before 相同。

Limitations：測試只驗證 controlled fake 與 in-memory contract；不宣稱 real process 或 network cancellation。

## Contract Coverage

- History、Cache、Settings、Favorite、Feedback logical isolation。
- Cache clear 不刪除 History 或 Favorite。
- History delete 不清除 Cache。
- 停用 history writes 阻止新寫入。
- visible limit `20` 不進行 physical eviction。
- Favorite 不因 visible limit 自動 eviction。
- user-triggered History deletion 與 Cache clear 分離。
- Feedback input/output 只有 explicit consent 才附加。
- 全部測試資料為 synthetic。
