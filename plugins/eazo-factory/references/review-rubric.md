# Mandatory review rubric

This review is a hard gate. A run passes only if all of the following are true:
- score at least 85;
- no blocking or important findings;
- every `control-audit.json` entry passes;
- core functionality at least 25/30;
- bugs at least 20/25.

Finding severities are exactly `blocking`, `important`, and `non_blocking`.

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
  "total_score": 88,
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
- Category maximums are exact and cannot be exceeded: `core_functionality <= 30`, `bugs <= 25`, `visual_quality <= 20`, `control_behavior <= 15`, `control_necessity <= 10`.
- `total_score` must equal the sum of `core_functionality + bugs + visual_quality + control_behavior + control_necessity`.
- The exact maximum `total_score` is 100.
- `findings` may be empty, but any finding with `severity: "blocking"` or `"important"` forces failure.

## control-audit.json schema

Use this exact shape:

```json
{
  "schema_version": "1.0",
  "interaction_map_control_ids": ["home-start-session"],
  "discovered_interactive_elements": [
    {
      "element_id": "home-idle-primary-button",
      "screen_state": "home:idle",
      "selector_or_description": "Primary button labeled Begin on home idle state",
      "owner": "product",
      "mapped_control_id": "home-start-session",
      "sdk_reference": null,
      "status": "mapped"
    }
  ],
  "entries": [
    {
      "control_id": "home-start-session",
      "feature_id": "breathing-session",
      "selector_or_description": "Primary button labeled Begin on home idle state",
      "mapped_requirement": "Breathing session: a user can start and complete a timed session",
      "acceptance_reference": "product-spec.features[breathing-session].acceptance[0]",
      "acceptance_text": "A user can start and complete a timed session",
      "action": "Click the primary button after selecting a duration",
      "observed_result": "Timer starts and paced breathing animation becomes visible",
      "status": "pass"
    }
  ],
  "coverage": {
    "interaction_map_control_count": 1,
    "audited_control_count": 1,
    "discovered_interactive_count": 1,
    "mapped_discovered_interactive_count": 1,
    "missing_control_ids": [],
    "extra_control_ids": [],
    "unmapped_discovered_interactive_elements": [],
    "status": "pass"
  }
}
```

Rules:
- `control_id` must match an `interaction-map.json` control id.
- `feature_id` must match the `feature_id` on the audited `interaction-map.json` control and a `features.id` from `product-spec.json`.
- `mapped_requirement` is required and must be a concise human-readable summary derived from `feature_id`, `acceptance_reference`, and `acceptance_text`.
- `acceptance_reference` must point to the accepted requirement being verified.
- `acceptance_text` must copy the exact acceptance text identified by `acceptance_reference`.
- `status` should be `"pass"` or `"fail"`.
- `entries` must include exactly one or more audit entries for every `interaction-map.json` control as needed across states.
- Compare the set of `interaction_map_control_ids` to the set of `entries.control_id`; fail if any control id is missing or extra.
- Every visible discovered interactive element must appear in `discovered_interactive_elements`.
- Product-owned elements use `owner: "product"`, map to exactly one `interaction-map.json` control ID, and set `sdk_reference` to `null`.
- Eazo SDK-owned elements use `owner: "eazo_sdk"`, set `mapped_control_id` to `null`, and provide a non-empty `sdk_reference` naming the official SDK-owned control.
- Fail if `coverage.missing_control_ids`, `coverage.extra_control_ids`, or `coverage.unmapped_discovered_interactive_elements` are non-empty.
- `coverage.status` is `"pass"` only when both compared control-id sets match exactly, all discovered interactive elements are mapped, and the four counts are internally consistent.

## Scoring guidance

- Core functionality (30): primary loop completeness, feature acceptance coverage, and state continuity.
- Bugs/runtime correctness (25): broken states, console/runtime issues, dead ends, localization mismatches, and data loss.
- Visual quality (20): composition, hierarchy, polish, consistency, and alignment with the chosen art direction.
- Control behavior (15): each control behaves as labeled and lands in the expected destination or state.
- Control necessity (10): every visible control is justified by the product spec; remove decorative or redundant controls.
