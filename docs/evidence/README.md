# Evidence

此目錄存放每個 Task 的完整驗證證據，由對應 Task 填入。

每個 Command 至少記錄：

```text
Task:
Command:
Working directory:
Start time:
End time:
Exit code:
Result:
Relevant stdout:
Relevant stderr:
Generated artifacts:
Git status before:
Git status after:
Limitations:
```

不得以摘要取代完整 Command Evidence，也不得將 `NOT_RUN` 標為 `PASS`。

目前 Task Evidence：

- [T-08 Reading mode](T-08/)
- [T-09 Expression mode](T-09/)
- [T-10 Progressive results and cancellation](T-10/)
- [T-12R Windows integration, desktop UX, and secure provider settings](T-12R/)
