# Task 3 report

Status: implemented deterministic preflight and official-template scaffolding for the Eazo Factory plugin.

Files changed:
- `plugins/eazo-factory/scripts/lib/common.sh`
- `plugins/eazo-factory/scripts/preflight.sh`
- `plugins/eazo-factory/scripts/scaffold-app.sh`
- `plugins/eazo-factory/tests/test-scaffold.sh`

What changed:
- Added shared Bash helpers for fatal errors, command checks, slug validation, and UTC timestamps.
- Added `preflight.sh` to verify required commands, writable output roots, valid slugs, and either a valid local starter override or canonical starter reachability.
- Added `scaffold-app.sh` to run preflight, clone the starter deterministically, detach template Git history, initialize a fresh Git repo, rewrite the package name, run `cleanup:demo`, create `design/` and `review/`, and write a Task 2-compatible `factory-run.json`.
- Added an end-to-end scaffold test that uses a fake local starter repo and a local `bun` stub so the override path is exercised without network access.

Verification run:
- `bash -n plugins/eazo-factory/scripts/lib/common.sh plugins/eazo-factory/scripts/preflight.sh plugins/eazo-factory/scripts/scaffold-app.sh plugins/eazo-factory/tests/test-scaffold.sh`
- `bash plugins/eazo-factory/tests/test-scaffold.sh`
- `bash plugins/eazo-factory/tests/test-manifest.sh`
- `git diff --check`

Notes / concerns:
- The current workspace does not have a real `bun` binary installed, so the test provides a PATH-local stub to validate the local-override flow end to end without changing runtime dependencies.
- `factory-run.json` records the canonical official starter URL and `main` branch to stay aligned with the Task 2 schema, even when a local override is used for deterministic testing.

Reviewer follow-up:
- Added destination symlink rejection before clone, with a regression test proving scaffolding fails and the external symlink target remains untouched.
- Moved initial `factory-run.json` creation to the post-clone/post-fresh-git phase before demo cleanup, using an interim `cleanup_pending` stage.
- Preserved cleanup failure evidence by streaming `cleanup:demo` output to both the command output and `review/cleanup-demo.log`, then updating `factory-run.json` to `status: failed` and `stage: cleanup_demo_failed`.

Follow-up verification:
- `bash plugins/eazo-factory/tests/test-scaffold.sh`

Final regression follow-up:
- Canonicalized the preflight-created output root to an absolute path before deriving the destination, run-state path, and cleanup log path.
- Added a regression test that invokes `scaffold-app.sh` from a temporary working directory with a relative output root and verifies the cleanup log lands under the generated app directory while the final run state remains `in_progress` / `scaffolded`.

Final verification:
- `bash plugins/eazo-factory/tests/test-scaffold.sh`
