# T-12R Secure Settings QA

## Contract

- Profile identity is exactly one `openai-default` profile。
- `ProviderProfile` stores only opaque `CredentialReference` metadata，沒有 raw key。
- Secure storage is the primary credential source；`OPENAI_API_KEY` is an explicit
  environment fallback for local development。
- Missing credential keeps OpenAI selected and returns typed configuration required；
  it does not silently switch to Fake。
- Successful save clears the visible API key field and status text never contains the
  credential。
- Runtime provider replacement is Application-owned and preserves current draft／mode。

Task: T-12R secure settings regression
Command: focused suite included `provider_settings_controller_test.dart`, `widget_t12r_ui_test.dart` and `openai_responses_analysis_provider_test.dart`
Working directory: disposable final clone `D:\\GitHub\\workspace\\lingolens-t12r-final4`
Result: `PASS`
Focused result: 48 tests passed；full suite result: 144 tests passed。
Synthetic data: `synthetic-t12r-credential` only；no real secret or network request。
