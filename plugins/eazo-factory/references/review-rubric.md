# Mandatory review rubric

This review is a hard gate. A run passes only if all of the following are true:
- score at least 85;
- no blocking findings;
- every `control-audit.json` entry passes;
- core functionality at least 25/30;
- bugs at least 20/25.

## review.json schema

Use this exact shape:

```json
{
  "schema_version": "1.0",
  "verdict": "pass",
  "core_functionality": 27,
  "bugs": 22,
  "visual_quality": 17,
  "control_behavior": 13,
  "control_necessity": 9,
  "findings": [
    {
      "severity": "non_blocking",
      "summary": "Secondary spacing is slightly tight on the completion state.",
      "evidence": "Observed on home:complete at 390px width.",
      "required_action": "Increase vertical gap between reflection field and save action."
    }
  ]
}
```

Rules:
- `verdict` is `"pass"` only when every gate condition above is satisfied.
- `core_functionality`, `bugs`, `visual_quality`, `control_behavior`, and `control_necessity` are numeric category scores.
- `findings` may be empty, but any finding with `severity: "blocking"` forces failure.

## control-audit.json schema

Use this exact shape:

```json
{
  "schema_version": "1.0",
  "entries": [
    {
      "control_id": "home-start-session",
      "selector_or_description": "Primary button labeled Begin on home idle state",
      "mapped_requirement": "Start the selected breathing session",
      "action": "Click the primary button after selecting a duration",
      "observed_result": "Timer starts and paced breathing animation becomes visible",
      "status": "pass"
    }
  ]
}
```

Rules:
- `control_id` must match an `interaction-map.json` control id.
- `mapped_requirement` should mirror the intended requirement being verified.
- `status` should be `"pass"` or `"fail"`.

## Scoring guidance

- Core functionality (30): primary loop completeness, feature acceptance coverage, and state continuity.
- Bugs/runtime correctness (25): broken states, console/runtime issues, dead ends, localization mismatches, and data loss.
- Visual quality (20): composition, hierarchy, polish, consistency, and alignment with the chosen art direction.
- Control behavior (15): each control behaves as labeled and lands in the expected destination or state.
- Control necessity (10): every visible control is justified by the product spec; remove decorative or redundant controls.
