# T-09 Verification Evidence

Frozen verification commit: 550413505530f4c2e7bb7fa7cab05c8ea8dc02c6

Disposable clone: D:\GitHub\workspace\lingolens-audit-t09

Commands and results:

    flutter --version
    Exit code: 0
    Flutter 3.41.5; Dart 3.11.3

    dart --version
    Exit code: 0
    Dart 3.11.3

    flutter pub get
    Exit code: 0
    Got dependencies; no manifest change

    dart format --output=none --set-exit-if-changed .
    Exit code: 0
    Formatted 32 files (0 changed)

    flutter analyze
    Exit code: 0
    No issues found!

    flutter test
    Exit code: 0
    All tests passed; 94 tests

    git diff --check
    Exit code: 0
    No output

The frozen clone was clean at the tested commit after generated disposable logs were removed:

    git status --short --branch
    ## HEAD (no branch)

No Flutter command was executed in D:\GitHub\LingoLens or any read-only Source Repository.
