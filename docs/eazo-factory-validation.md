# Eazo Factory Validation

Use a new Codex thread after installing or updating the plugin.

## Automated checks

```bash
bash plugins/eazo-factory/tests/test-manifest.sh
bash plugins/eazo-factory/tests/test-scaffold.sh
bash plugins/eazo-factory/tests/test-verify.sh
```

Validate the plugin and all bundled skills:

```bash
PYTHONPATH=/path/to/PyYAML \
  python3 /path/to/plugin-creator/scripts/validate_plugin.py plugins/eazo-factory

for skill in eazo-idea eazo-design eazo-build eazo-review eazo-factory; do
  PYTHONPATH=/path/to/PyYAML \
    python3 /path/to/skill-creator/scripts/quick_validate.py \
    "plugins/eazo-factory/skills/$skill"
done
```

## Discovery check

```bash
codex exec --ephemeral --sandbox read-only \
  "List the Eazo Factory plugin skills available to you and summarize when each triggers."
```

Expected skills:

- `eazo-factory`
- `eazo-idea`
- `eazo-design`
- `eazo-build`
- `eazo-review`

## Manual full-generation prompts

Run each prompt in a new writable test workspace:

```text
@eazo-factory Create a Matisse-inspired two-minute breathing meditation app.
```

```text
@eazo-factory Create a quiet editorial daily reflection journal.
```

```text
@eazo-factory Create a playful Bauhaus kitchen timer utility.
```

## Official-template smoke result

On June 25, 2026, `scaffold-app.sh` successfully cloned and cleaned official template commit:

```text
0067f106872c7f5372916e4fdbd7455eee006a38
```

The cleaned template completed `bun run build`. Its unchanged language switcher produced one upstream ESLint error under the downloaded dependency versions, so generated apps must repair that lint issue before the factory verifier can pass. This smoke result validates template access, cleanup, Git detachment, dependency installation, and production build; it is not a substitute for the three full app acceptance runs below.

## Evidence record

Complete one row per generated app.

| Prompt | App path | Template commit | Product/design artifacts | Lint/build | Preview URL | Review score | Controls discovered | Controls passed | Unresolved findings |
|---|---|---|---|---|---|---:|---:|---:|---|
| Meditation |  |  |  |  |  |  |  |  |  |
| Journal |  |  |  |  |  |  |  |  |  |
| Utility |  |  |  |  |  |  |  |  |  |

Each run passes only when:

- the official template commit is recorded;
- all required artifacts exist;
- lint and build pass;
- a healthy preview URL is returned;
- independent review score is at least 85;
- core functionality is at least 25/30;
- bugs/runtime correctness is at least 20/25;
- every discovered control maps to the interaction inventory and passes;
- no blocking or important finding remains.
