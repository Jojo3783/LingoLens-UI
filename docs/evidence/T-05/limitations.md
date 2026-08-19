# T-05 Limitations and Boundary

- `flutter build windows` is `BLOCKED` by the missing CMake executable path reported in `build-results.md`.
- macOS build and runtime verification are `NOT_RUN` on the Windows host.
- The provider is deterministic fake-only; no real AI, CLI, HTTP, model, or secret path exists.
- Cancellation is verified for the controlled fake delay. This does not claim cancellation of a real external process or network request.
- No durable persistence, visible history, cache, schema, migration, hotkey, selected-text capture, clipboard, floating window, TTS, or native platform integration is implemented in T-05.
- Progressive behavior is explicitly `FULL_ONLY_FAKE`; no two-stage, stream, or preview strategy is implemented.
- No raw user text is written to logs or evidence, and no credentials or private data were added.
- These limitations are bounded T-05 observations and do not authorize T-06.
