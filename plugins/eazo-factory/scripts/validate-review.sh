#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

APP_DIR="${1:-}"
MODE="${2:-}"
[ -n "$APP_DIR" ] || die "usage: validate-review.sh APP_DIR [--require-pass]"
[ -d "$APP_DIR" ] || die "app directory does not exist: $APP_DIR"
[ -z "$MODE" ] || [ "$MODE" = "--require-pass" ] \
  || die "unknown option: $MODE"

APP_DIR="$(cd "$APP_DIR" && pwd -P)"

node - "$APP_DIR" "$MODE" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const appDir = process.argv[2];
const requirePass = process.argv[3] === "--require-pass";
const errors = [];

function read(relativePath) {
  const fullPath = path.join(appDir, relativePath);
  try {
    return JSON.parse(fs.readFileSync(fullPath, "utf8"));
  } catch (error) {
    errors.push(`${relativePath}: ${error.message}`);
    return null;
  }
}

function sameSet(left, right) {
  return left.length === right.length &&
    [...new Set(left)].length === left.length &&
    [...new Set(right)].length === right.length &&
    left.every((item) => right.includes(item));
}

const interactionMap = read("design/interaction-map.json");
const productSpec = read("product-spec.json");
const verification = read("review/verification.json");
const review = read("review/review.json");
const audit = read("review/control-audit.json");

for (const [name, payload] of [
  ["product-spec.json", productSpec],
  ["design/interaction-map.json", interactionMap],
  ["review/verification.json", verification],
  ["review/review.json", review],
  ["review/control-audit.json", audit],
]) {
  if (payload?.schema_version !== "1.0") {
    errors.push(`${name}: schema_version must be 1.0`);
  }
}

const controlIds = Array.isArray(interactionMap?.controls)
  ? interactionMap.controls.map((control) => control?.id).filter((id) => typeof id === "string")
  : [];
if (!interactionMap || !Array.isArray(interactionMap.controls)) {
  errors.push("design/interaction-map.json: controls must be an array");
} else if (interactionMap.controls.length === 0) {
  errors.push("design/interaction-map.json: controls must not be empty");
}
const features = new Map(
  Array.isArray(productSpec?.features)
    ? productSpec.features
      .filter((feature) => typeof feature?.id === "string")
      .map((feature) => [feature.id, feature])
    : [],
);
const controls = new Map(
  Array.isArray(interactionMap?.controls)
    ? interactionMap.controls
      .filter((control) => typeof control?.id === "string")
      .map((control) => [control.id, control])
    : [],
);
if (features.size === 0) errors.push("product-spec.json: features must not be empty");
if (controls.size !== controlIds.length) {
  errors.push("design/interaction-map.json: control IDs must be unique and non-empty");
}

const scoreFields = {
  core_functionality: 30,
  bugs: 25,
  visual_quality: 20,
  control_behavior: 15,
  control_necessity: 10,
};
let computedTotal = 0;
for (const [field, max] of Object.entries(scoreFields)) {
  const value = review?.[field];
  if (!Number.isFinite(value) || value < 0 || value > max) {
    errors.push(`review/review.json: ${field} must be between 0 and ${max}`);
  } else {
    computedTotal += value;
  }
}
if (review?.total_score !== computedTotal) {
  errors.push("review/review.json: total_score does not equal category sum");
}
if (!["pass", "fail"].includes(review?.verdict)) {
  errors.push("review/review.json: verdict must be pass or fail");
}
if (!Array.isArray(review?.findings)) {
  errors.push("review/review.json: findings must be an array");
}
const allowedSeverities = new Set(["blocking", "important", "non_blocking"]);
for (const finding of review?.findings ?? []) {
  if (!allowedSeverities.has(finding?.severity)) {
    errors.push(`review/review.json: invalid finding severity ${finding?.severity}`);
  }
  for (const field of ["summary", "evidence", "required_action"]) {
    if (typeof finding?.[field] !== "string" || !finding[field].trim()) {
      errors.push(`review/review.json: finding missing ${field}`);
    }
  }
}

if (!Array.isArray(audit?.interaction_map_control_ids) ||
    !sameSet(audit.interaction_map_control_ids, controlIds)) {
  errors.push("review/control-audit.json: interaction_map_control_ids must exactly match the interaction map");
}
if (!Array.isArray(audit?.entries)) {
  errors.push("review/control-audit.json: entries must be an array");
}
const auditedIds = (audit?.entries ?? []).map((entry) => entry?.control_id);
if (!sameSet([...new Set(auditedIds)], controlIds)) {
  errors.push("review/control-audit.json: audited control IDs must cover the interaction map exactly");
}
for (const entry of audit?.entries ?? []) {
  if (!controlIds.includes(entry?.control_id)) {
    errors.push(`review/control-audit.json: unknown control ${entry?.control_id}`);
  }
  if (entry?.status !== "pass" && entry?.status !== "fail") {
    errors.push(`review/control-audit.json: invalid status for ${entry?.control_id}`);
  }
  for (const field of [
    "feature_id",
    "selector_or_description",
    "mapped_requirement",
    "acceptance_reference",
    "acceptance_text",
    "action",
    "observed_result",
  ]) {
    if (typeof entry?.[field] !== "string" || !entry[field].trim()) {
      errors.push(`review/control-audit.json: ${entry?.control_id ?? "entry"} missing ${field}`);
    }
  }
  const control = controls.get(entry?.control_id);
  const feature = features.get(entry?.feature_id);
  if (!control || control.feature_id !== entry?.feature_id || !feature) {
    errors.push(`review/control-audit.json: invalid feature mapping for ${entry?.control_id}`);
  } else {
    const acceptanceMatch = entry.acceptance_reference?.match(
      /^product-spec\.features\[([^\]]+)\]\.acceptance\[(\d+)\]$/,
    );
    const acceptanceIndex = acceptanceMatch ? Number(acceptanceMatch[2]) : -1;
    const expectedAcceptance = acceptanceMatch && acceptanceMatch[1] === entry.feature_id
      ? feature.acceptance?.[acceptanceIndex]
      : undefined;
    if (typeof expectedAcceptance !== "string" || entry.acceptance_text !== expectedAcceptance) {
      errors.push(`review/control-audit.json: invalid acceptance reference for ${entry?.control_id}`);
    }
  }
}

if (!Array.isArray(audit?.discovered_interactive_elements)) {
  errors.push("review/control-audit.json: discovered_interactive_elements must be an array");
}
for (const element of audit?.discovered_interactive_elements ?? []) {
  if (element?.status !== "mapped") {
    errors.push(`review/control-audit.json: discovered element ${element?.element_id} is not mapped`);
  }
  if (element?.owner === "product") {
    if (!controlIds.includes(element?.mapped_control_id) || element?.sdk_reference !== null) {
      errors.push(`review/control-audit.json: invalid product mapping for ${element?.element_id}`);
    }
  } else if (element?.owner === "eazo_sdk") {
    if (element?.mapped_control_id !== null ||
        typeof element?.sdk_reference !== "string" ||
        !element.sdk_reference.trim()) {
      errors.push(`review/control-audit.json: invalid SDK ownership for ${element?.element_id}`);
    }
  } else {
    errors.push(`review/control-audit.json: invalid owner for ${element?.element_id}`);
  }
}
const discoveredProductIds = (audit?.discovered_interactive_elements ?? [])
  .filter((element) => element?.owner === "product")
  .map((element) => element?.mapped_control_id);
if (!sameSet([...new Set(discoveredProductIds)], controlIds)) {
  errors.push("review/control-audit.json: discovered product controls must cover the interaction map exactly");
}
const sourceInventory = Array.isArray(verification?.source_control_inventory)
  ? verification.source_control_inventory
  : [];
const sourceProductIds = sourceInventory
  .filter((element) => element?.owner === "product")
  .map((element) => element?.id);
if (!sameSet([...new Set(sourceProductIds)], controlIds)) {
  errors.push("review/verification.json: source product controls must cover the interaction map exactly");
}
const sourceSdkIds = [...new Set(
  sourceInventory
    .filter((element) => element?.owner === "eazo_sdk")
    .map((element) => element?.id),
)];
const discoveredSdkIds = [...new Set(
  (audit?.discovered_interactive_elements ?? [])
    .filter((element) => element?.owner === "eazo_sdk")
    .map((element) => element?.sdk_reference),
)];
for (const sdkId of sourceSdkIds) {
  if (!discoveredSdkIds.includes(sdkId)) {
    errors.push(`review/control-audit.json: missing reachable SDK control ${sdkId}`);
  }
}

const coverage = audit?.coverage;
if (!coverage || typeof coverage !== "object") {
  errors.push("review/control-audit.json: coverage is required");
} else {
  const discovered = audit.discovered_interactive_elements ?? [];
  const mappedDiscovered = discovered.filter((element) =>
    element?.owner === "eazo_sdk" ||
    (element?.owner === "product" && controlIds.includes(element?.mapped_control_id)),
  );
  const expectedCounts = {
    interaction_map_control_count: controlIds.length,
    audited_control_count: new Set(auditedIds).size,
    discovered_interactive_count: discovered.length,
    mapped_discovered_interactive_count: mappedDiscovered.length,
  };
  for (const [field, expected] of Object.entries(expectedCounts)) {
    if (coverage[field] !== expected) {
      errors.push(`review/control-audit.json: ${field} must equal ${expected}`);
    }
  }
  for (const field of [
    "missing_control_ids",
    "extra_control_ids",
    "unmapped_discovered_interactive_elements",
  ]) {
    if (!Array.isArray(coverage[field])) {
      errors.push(`review/control-audit.json: ${field} must be an array`);
    }
  }
}

const unresolvedRequiredFinding = (review?.findings ?? []).some(
  (finding) => finding?.severity === "blocking" || finding?.severity === "important",
);
const allEntriesPass = (audit?.entries ?? []).every((entry) => entry?.status === "pass");
const cleanCoverage = audit?.coverage?.status === "pass" &&
  (audit?.coverage?.missing_control_ids?.length ?? -1) === 0 &&
  (audit?.coverage?.extra_control_ids?.length ?? -1) === 0 &&
  (audit?.coverage?.unmapped_discovered_interactive_elements?.length ?? -1) === 0;
const passConditions = review?.verdict === "pass" &&
  verification?.status === "pass" &&
  review?.total_score >= 85 &&
  review?.core_functionality >= 25 &&
  review?.bugs >= 20 &&
  !unresolvedRequiredFinding &&
  allEntriesPass &&
  cleanCoverage;

if (review?.verdict === "pass" && !passConditions) {
  errors.push("review/review.json: pass verdict does not satisfy all hard gates");
}
if (requirePass && !passConditions) {
  errors.push("review artifacts do not satisfy final pass conditions");
}

if (errors.length) {
  for (const error of errors) process.stderr.write(`${error}\n`);
  process.exit(1);
}
process.stdout.write(requirePass ? "review gate passed\n" : "review artifacts valid\n");
NODE
