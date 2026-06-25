# Task 2 Report

## Scope

Implemented Task 2 under `plugins/eazo-factory/references/`:
- stable artifact schema references;
- Eazo template precedence policy;
- mandatory review rubric;
- three bounded art-direction references.

Created:
- `plugins/eazo-factory/references/product-spec-schema.md`
- `plugins/eazo-factory/references/design-system-schema.md`
- `plugins/eazo-factory/references/interaction-map-schema.md`
- `plugins/eazo-factory/references/factory-run-schema.md`
- `plugins/eazo-factory/references/review-rubric.md`
- `plugins/eazo-factory/references/eazo-template-policy.md`
- `plugins/eazo-factory/references/art-directions/matisse-cut-paper.md`
- `plugins/eazo-factory/references/art-directions/bauhaus-playful.md`
- `plugins/eazo-factory/references/art-directions/quiet-editorial.md`

## Requirements mapping

### Stable artifact schemas

- `product-spec-schema.md`
  - Preserves the exact required field names and nested shapes from the brief.
  - States the mandatory single primary loop.
  - States that every feature requires at least one acceptance condition.

- `design-system-schema.md`
  - Defines `design-tokens.json` with the required top-level keys:
    `schema_version`, `art_direction`, `palette`, `typography`, `spacing`, `radii`, `shadows`, `illustration`, `motion`, `components`.

- `interaction-map-schema.md`
  - Defines `interaction-map.json` with the exact required control entry shape.
  - States explicitly that image elements that look like controls but cannot map one-to-one must be removed.

- `factory-run-schema.md`
  - Preserves the exact `factory-run.json` field names and nesting from the brief.

- `review-rubric.md`
  - Defines `review.json` with the required fields:
    `verdict`, `core_functionality`, `bugs`, `visual_quality`, `control_behavior`, `control_necessity`, `findings`.
  - Defines `control-audit.json` entries with:
    `control_id`, `selector_or_description`, `mapped_requirement`, `action`, `observed_result`, `status`.

### Template policy

- `eazo-template-policy.md`
  - Uses the exact precedence order from the brief.
  - Requires reading `AGENTS.md`, `package.json`, `.env.example`, `src/app/layout.tsx`, and only the capability examples selected in `product-spec.json`.

### Mandatory review rubric

- `review-rubric.md`
  - Uses the required 100-point category split:
    - Core functionality: 30
    - Bugs/runtime correctness: 25
    - Visual quality: 20
    - Control behavior: 15
    - Control necessity: 10
  - Encodes the hard-gate pass conditions exactly:
    - score at least 85;
    - no blocking findings;
    - every `control-audit.json` entry passes;
    - core functionality at least 25/30;
    - bugs at least 20/25.

### Art-direction references

- `art-directions/matisse-cut-paper.md`
  - Emphasizes original cut-paper composition and explicitly forbids copying existing artwork.

- `art-directions/bauhaus-playful.md`
  - Defines geometric, grid-led direction with bounded motion and control discipline.

- `art-directions/quiet-editorial.md`
  - Defines restrained editorial composition, palette, typography, motion, and control discipline.

## RED → GREEN evidence

### RED

Ran the brief’s checks before the reference directory existed.

Command:

```bash
! rg -n 'TBD|TODO|FIXME|implement later|fill in' plugins/eazo-factory/references
```

Observed:

```text
rg: plugins/eazo-factory/references: IO error for operation on plugins/eazo-factory/references: No such file or directory (os error 2)
```

Command:

```bash
rg -n '"schema_version": "1.0"' plugins/eazo-factory/references
```

Observed:

```text
rg: plugins/eazo-factory/references: IO error for operation on plugins/eazo-factory/references: No such file or directory (os error 2)
```

This established a failing baseline before implementation.

### GREEN

Command:

```bash
! rg -n 'TBD|TODO|FIXME|implement later|fill in' plugins/eazo-factory/references
```

Result:
- Exit 0
- No matches

Command:

```bash
rg -n '"schema_version": "1.0"' plugins/eazo-factory/references
```

Result:
- Exit 0
- Matches found in all JSON artifact references:
  - `product-spec-schema.md`
  - `design-system-schema.md`
  - `interaction-map-schema.md`
  - `factory-run-schema.md`
  - `review-rubric.md` (`review.json` and `control-audit.json`)

Additional contract checks:

```bash
rg -n 'score at least 85|no blocking findings|every `control-audit.json` entry passes|core functionality at least 25/30|bugs at least 20/25' plugins/eazo-factory/references/review-rubric.md
rg -n '1\. Checked-out template AGENTS\.md|2\. Checked-out template implementation and package scripts|3\. Checked-out template \.env\.example and deployment configuration|4\. Plugin references|5\. General framework conventions|AGENTS\.md|package\.json|\.env\.example|src/app/layout\.tsx|only the capability examples selected in `product-spec\.json`' plugins/eazo-factory/references/eazo-template-policy.md
```

Result:
- Exit 0
- Required rubric gate text and template-policy precedence/read requirements all present.

## Self-review

Performed a manual consistency review across all new reference files:
- schema names and field names align with the brief;
- `feature_id` and control audit mapping language line up with `product-spec.json` and `interaction-map.json`;
- template policy precedence matches the exact order required;
- rubric hard gates use the required thresholds and cannot pass with blocking findings or failed control audits;
- art-direction references are concise, bounded, and include palette, composition, typography, imagery, motion, forbidden clichés, and UI-control discipline.

One issue found during self-review:
- The first draft of `review-rubric.md` expressed the pass thresholds equivalently but not in the brief’s exact wording.
- Fixed by changing the gate bullets to the exact required phrases.

## Files outside task ownership

This report was added at the required path:
- `.superpowers/sdd/task-2-report.md`

No plugin files outside `plugins/eazo-factory/references/` were modified.

## Reviewer remediation update

Addressed all requested High and Medium findings, plus the two Low contract-stability findings:

- Made full control coverage mathematically explicit in `review-rubric.md` by adding:
  - `interaction_map_control_ids`
  - `discovered_interactive_elements`
  - `coverage`
  - normative set comparison and count-consistency rules
- Bound `interaction-map.json` fields normatively:
  - `screen` must match `product-spec.json` `screens.id`
  - `destination` must be either `<screen-id>:<state>` from product spec or a documented external/platform destination
  - `destination_reference` now carries the stable destination binding
- Replaced free-text-only control audit mapping with stable references:
  - `feature_id`
  - `mapped_requirement` restored as the required concise human-readable summary derived from the stable references
  - `acceptance_reference`
  - `acceptance_text`
- Defined `total_score` explicitly and tied it to the exact category maxima and total maximum of 100.
- Stated the canonical starter template URL and `main` branch normatively in both:
  - `factory-run-schema.md`
  - `eazo-template-policy.md`
- Enumerated the allowed `art_direction` slugs in `design-system-schema.md`:
  - `matisse-cut-paper`
  - `bauhaus-playful`
  - `quiet-editorial`
- Defined stable shapes for `factory-run.json` artifact records and verification records.

### RED baseline for reviewer fixes

Before patching, targeted grep checks for the new reviewer requirements failed because the required phrases and stable fields were not present.

Commands run:

```bash
rg -n 'exactly one or more audit entries|missing|extra|unmapped|interaction_map_control_ids|audited_control_ids|discovered_interactive_elements' plugins/eazo-factory/references/review-rubric.md
rg -n 'documented external/platform destination|<screen-id>:<state>|screen must match|screens.id' plugins/eazo-factory/references/interaction-map-schema.md
```

Observed:
- both commands exited 1 with no matches

Additional baseline note:
- JSON code-fence parsing already passed before these fixes, so JSON validity was preserved while tightening the contracts.

### GREEN verification after reviewer fixes

Re-ran the original Task 2 checks:

```bash
! rg -n 'TBD|TODO|FIXME|implement later|fill in' plugins/eazo-factory/references
rg -n '"schema_version": "1.0"' plugins/eazo-factory/references
```

Observed:
- placeholder scan exited 0 with no matches
- schema-version scan exited 0 and matched all JSON artifact references

Ran targeted reviewer-fix checks:

```bash
rg -n 'exactly one or more audit entries|missing_control_ids|extra_control_ids|unmapped_discovered_interactive_elements|interaction_map_control_ids|discovered_interactive_elements|coverage.status' plugins/eazo-factory/references/review-rubric.md
rg -n 'screen` must match|<screen-id>:<state>|documented external/platform destination|destination_reference|product_screen_state|external_platform' plugins/eazo-factory/references/interaction-map-schema.md
rg -n 'total_score|sum of `core_functionality \+ bugs \+ visual_quality \+ control_behavior \+ control_necessity`|maximum `total_score` is 100|<= 30|<= 25|<= 20|<= 15|<= 10' plugins/eazo-factory/references/review-rubric.md
rg -n 'https://github.com/EazoAI/eazo-creator-nextjs-template.git|branch `main`|matisse-cut-paper|bauhaus-playful|quiet-editorial' plugins/eazo-factory/references/eazo-template-policy.md plugins/eazo-factory/references/design-system-schema.md plugins/eazo-factory/references/factory-run-schema.md
```

Observed:
- all commands exited 0
- review rubric now contains explicit control-set comparison, discovered-element mapping, count fields, and coverage pass/fail conditions
- interaction map now contains normative `screen` and `destination` binding rules plus `destination_reference`
- review rubric now contains `total_score`, exact per-category maximums, and total maximum 100
- canonical template URL, `main` branch, and allowed `art_direction` slugs are all present

Ran JSON parse checks across all JSON fenced examples:

```bash
python3 - <<'PY'
from pathlib import Path
import json,re,sys
paths = sorted(Path('plugins/eazo-factory/references').rglob('*.md'))
failed=[]
for p in paths:
    text=p.read_text()
    blocks=re.findall(r'```json\n(.*?)\n```', text, re.S)
    for i,b in enumerate(blocks,1):
        try:
            json.loads(b)
        except Exception as e:
            failed.append((str(p),i,str(e)))
if failed:
    for item in failed:
        print(item)
    sys.exit(1)
print('all-json-blocks-parse')
PY
```

Observed:
- exited 0
- output: `all-json-blocks-parse`

## Strict-spec follow-up: restore `mapped_requirement`

The shipped `control-audit.json` example temporarily omitted the required `mapped_requirement` field while the report still described it. Fixed by restoring `mapped_requirement` in every audit entry schema example and defining it normatively as a concise human-readable summary derived from `feature_id`, `acceptance_reference`, and `acceptance_text`.

### RED baseline

Commands run:

```bash
rg -n 'mapped_requirement' plugins/eazo-factory/references/review-rubric.md .superpowers/sdd/task-2-report.md
python3 - <<'PY'
from pathlib import Path
text = Path('plugins/eazo-factory/references/review-rubric.md').read_text()
start = text.index('## control-audit.json schema')
section = text[start:]
print('mapped_requirement_in_schema', 'mapped_requirement' in section.split('```json',1)[1].split('```',1)[0])
PY
```

Observed:
- `mapped_requirement` appeared in the report but not in the shipped schema example
- Python check output: `mapped_requirement_in_schema False`

### GREEN verification

Commands run:

```bash
rg -n 'mapped_requirement|concise human-readable summary derived from `feature_id`, `acceptance_reference`, and `acceptance_text`' plugins/eazo-factory/references/review-rubric.md .superpowers/sdd/task-2-report.md
python3 - <<'PY'
from pathlib import Path
import json,re
text = Path('plugins/eazo-factory/references/review-rubric.md').read_text()
start = text.index('## control-audit.json schema')
section = text[start:]
print('mapped_requirement_in_schema', 'mapped_requirement' in section.split('```json',1)[1].split('```',1)[0])
for block in re.findall(r'```json\n(.*?)\n```', text, re.S):
    json.loads(block)
print('review-rubric-json-parse-pass')
PY
```

Observed:
- `mapped_requirement` now appears in both the shipped schema and the report
- Python check output:
  - `mapped_requirement_in_schema True`
  - `review-rubric-json-parse-pass`
