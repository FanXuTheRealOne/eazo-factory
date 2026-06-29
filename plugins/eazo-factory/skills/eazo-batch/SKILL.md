---
name: eazo-batch
description: Use when the user asks Eazo Factory to batch-generate multiple apps from many links, screenshots, a links.txt file, a jobs.json file, or parallel Codex workers.
---

# Eazo Batch

Run many independent Eazo Factory jobs by launching separate `codex exec` workers with a bounded concurrency limit.

## When to use

Use this skill when the user asks for:

- 批量生成, 一堆链接, 100 个小红书链接, 并行跑, 多开 Codex;
- a file such as `links.txt`, `xhs-links.txt`, `jobs.json`, or `sources.json`;
- “把当前 directory 里的 file 里的链接都生成 app”.

Do not manually loop through many apps in the current conversation. Batch mode exists so each app gets its own Codex worker, output directory, logs, final message, and `batch-report.json`.

## Input formats

`links.txt`:

```text
https://www.xiaohongshu.com/explore/...
https://www.xiaohongshu.com/explore/...
```

`jobs.json`:

```json
[
  {
    "name": "sleep-checkin",
    "source": "https://www.xiaohongshu.com/explore/...",
    "style": "soft paper collage, cozy night",
    "notes": "Make it a daily check-in app",
    "screenshots": ["./screenshots/sleep-01.png"]
  }
]
```

Relative screenshot paths resolve from the JSON file directory.

## How to run

Resolve the plugin root as two directories above this skill, then run:

```bash
node <plugin-root>/bin/eazo-batch.mjs run <input-file> --out <output-dir> --concurrency 2
```

Useful options:

- `--dry-run`: only produce prompts and `batch-report.json`, no token-heavy workers.
- `--concurrency N`: number of parallel `codex exec` workers; default 2.
- `--style "..."`: shared visual direction appended to every job.
- `--extra "..."`: extra instruction appended to every job.
- `--sandbox workspace-write`: default safer sandbox.
- `--sandbox danger-full-access --yes`: use only if the user explicitly wants fewer sandbox limits.

The CLI launches workers like:

```bash
codex exec --cd <batch-dir> --skip-git-repo-check --sandbox workspace-write --ask-for-approval never --output-last-message <job>/final.md "<@eazo-factory prompt>"
```

## Interaction policy

- If no input file is provided, ask for the file path or ask the user to create `links.txt`.
- If the user provides raw links in the message, write them to a temporary `links.txt` only if file writing is clearly in scope; otherwise ask where to save the batch run.
- Default concurrency is 2. For 6+ workers, warn that it is token-heavy and ask for explicit confirmation unless the user already said they accept high token usage.
- If the run fails because a Xiaohongshu page is login/verification blocked, return the affected job paths and tell the user to log in locally or add screenshots, then rerun that subset.

## Output to report back

Always return:

- `batch-report.json` path;
- total / succeeded / failed / dry-run counts;
- app output root;
- failed job `final.md` or `stderr.log` paths if any.
