# T-08 Reading Widget Evidence

Task：`T-08`
Working directory：`D:\GitHub\workspace\lingolens-audit-t08`
Tested commit：`ab6012f3b2a1a919eec9999cb2bfae9f1350d949`
Result：`PASS`

Command：`flutter test test/widget_reading_mode_test.dart`

- Start／End：`2026-07-28`；MCP command wrapper 未提供細部時間戳
- Exit code：`0`
- Relevant stdout：`All tests passed!`；`7` tests passed
- Relevant stderr：僅有 dependency resolution 的可更新套件提示
- Generated artifacts：無
- Git status before／after：frozen clone；implementation commit unchanged

Coverage：

- Translation → Copy／Listen（Fake）→ Sentence analysis → Grammar → Vocabulary → Nuance hierarchy
- Copy／Listen（Fake）使用 Translation
- action-state rebuild 保留 result／translation element identity 與 `SelectionArea`
- Save、Favorite、Feedback 仍可操作，Feedback 預設不附加 content
- long output、desktop width、narrow viewport 與 horizontal overflow guard
- Expression regression 不顯示 Reading sections
