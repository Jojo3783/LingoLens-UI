# T-08R Visual and Semantics Evidence

## Existing T-08 screenshot

Path: `docs/evidence/T-08/reading-mode.png`
Dimensions: `1000 x 1800`
File size: `29900` bytes
SHA-256: `a0ab1a3f5710c25976b9bb589b63201c93d0ded20336032132fa5b74a4a08404`

Generation command in the disposable verification clone:

```text
flutter test --update-goldens test/visual/reading_mode_screenshot_test.dart
```

The existing T-08 PNG was not modified by T-08R. It remains valid as layout／geometry evidence for hierarchy, action placement, long-output layout, and session panel presence. Text readability in the screenshot is `UNVERIFIED_IN_SCREENSHOT`; this evidence does not claim readable glyphs.

No production font dependency was added.

## Semantics evidence

Path: `docs/evidence/T-08R/semantics-tree.txt`
Type: deterministic semantics contract evidence derived from passing widget assertions

The temporary raw semantics dump harness was not used as evidence because it hung and produced no valid artifact. The text contract lists the exact expected and asserted mode-aware keys, labels, body semantics, and mode-switch cleanup. Its source test command exited `0` with `16 tests passed`.
