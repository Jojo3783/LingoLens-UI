# T-08R2 Verification Traceability

## Commit identities

- Previous stale T-08R tested-implementation reference in Root `handoff.md`: `ab6012f3b2a1a919eec9999cb2bfae9f1350d949`.
- Original T-08 implementation commit: `ab6012f3b2a1a919eec9999cb2bfae9f1350d949`.
- Correct T-08R remediation implementation commit: `f0956b11a0c0b39b3aa23c8968035ee75ead4bff`.
- T-08R prior final delivery HEAD and T-08R2 starting HEAD: `c3d9a751bf2bef1f992eddc3c2bb6b54487ac2c8`.
- T-08R2 governance correction commit, used as the frozen verification commit: `931c4c9fc43da1e077e728fa39c34a100ea55729`.
- Final delivery HEAD: recorded by the final `git rev-parse HEAD`, `git ls-remote`, and PR metadata receipt after the evidence commit; the exact final SHA is reported in the final Team Review report rather than recursively copied into its own commit.

## Frozen verification

Disposable clone: `D:\GitHub\workspace\lingolens-audit-t08r2`

The clone was checked out detached at exact commit `931c4c9fc43da1e077e728fa39c34a100ea55729` before running Flutter commands. No claim is made that a different commit was tested.

## Remaining diff boundary

After the evidence commit, run:

```text
git diff --name-only 931c4c9fc43da1e077e728fa39c34a100ea55729..HEAD -- .
git diff --name-only c3d9a751bf2bef1f992eddc3c2bb6b54487ac2c8..HEAD -- lib/ test/ pubspec.yaml pubspec.lock windows/ macos/
```

The first command must contain only governance and `docs/evidence/T-08R2/` files. The second command must be empty. The final command receipt records the exact output and final HEAD.
