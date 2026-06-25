#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

APP_DIR="${1:-}"
[ -n "$APP_DIR" ] || die "usage: verify-app.sh APP_DIR"
[ -d "$APP_DIR" ] || die "app directory does not exist: $APP_DIR"

APP_DIR="$(cd "$APP_DIR" && pwd -P)"
mkdir -p "$APP_DIR/review"

STATIC_RESULT="$(mktemp "${TMPDIR:-/tmp}/eazo-static-verification.XXXXXX")"
LINT_LOG="$APP_DIR/review/lint.log"
BUILD_LOG="$APP_DIR/review/build.log"
trap 'rm -f "$STATIC_RESULT"' EXIT

node - "$APP_DIR" "$STATIC_RESULT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const appDir = process.argv[2];
const outputPath = process.argv[3];
const findings = [];

function add(code, message, file = null) {
  findings.push({ severity: "blocking", code, message, file });
}

function readJson(relativePath) {
  const fullPath = path.join(appDir, relativePath);
  try {
    return JSON.parse(fs.readFileSync(fullPath, "utf8"));
  } catch (error) {
    add("invalid_json", `${relativePath} is not valid JSON: ${error.message}`, relativePath);
    return null;
  }
}

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...walk(fullPath));
    else if (entry.isFile()) files.push(fullPath);
  }
  return files;
}

const requiredFiles = [
  "package.json",
  "AGENTS.md",
  ".env.example",
  "product-spec.json",
  "factory-run.json",
  "design/ui-reference.png",
  "design/design-tokens.json",
  "design/interaction-map.json",
  "src/app/layout.tsx",
  "src/i18n/locales/en-US.json",
  "src/i18n/locales/zh-CN.json",
];

for (const relativePath of requiredFiles) {
  if (!fs.existsSync(path.join(appDir, relativePath))) {
    add("missing_required_file", `Missing required file: ${relativePath}`, relativePath);
  }
}

const pkg = fs.existsSync(path.join(appDir, "package.json"))
  ? readJson("package.json")
  : null;
if (pkg) {
  if (typeof pkg.packageManager !== "string" || !pkg.packageManager.startsWith("bun@")) {
    add("invalid_package_manager", "packageManager must start with bun@", "package.json");
  }
  if (!pkg.dependencies || typeof pkg.dependencies["@eazo/sdk"] !== "string") {
    add("missing_eazo_sdk", "@eazo/sdk must remain a dependency", "package.json");
  }
}

const imagePath = path.join(appDir, "design/ui-reference.png");
if (fs.existsSync(imagePath)) {
  const image = fs.readFileSync(imagePath);
  const pngSignature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (image.length < 24 || !image.subarray(0, 8).equals(pngSignature)) {
    add("invalid_ui_reference", "design/ui-reference.png must be a real PNG image", "design/ui-reference.png");
  }
}

const run = fs.existsSync(path.join(appDir, "factory-run.json"))
  ? readJson("factory-run.json")
  : null;
if (run && (!run.starter || typeof run.starter.commit !== "string" || !run.starter.commit.trim())) {
  add("missing_starter_commit", "factory-run.json starter.commit must be non-empty", "factory-run.json");
}
if (run?.starter?.source !== "https://github.com/EazoAI/eazo-creator-nextjs-template.git" ||
    run?.starter?.branch !== "main") {
  add(
    "invalid_template_provenance",
    "factory-run.json must record the canonical Eazo template main branch",
    "factory-run.json",
  );
}

if (fs.existsSync(path.join(appDir, "src/components/todo-list"))) {
  add(
    "unchanged_demo_artifact",
    "The template todo-list demo directory must be removed",
    "src/components/todo-list",
  );
}

const sourceRoot = path.join(appDir, "src");
const sourceFiles = walk(sourceRoot).filter((file) => /\.(?:[cm]?[jt]sx?|json)$/.test(file));
const sourceText = sourceFiles
  .map((file) => {
    const text = fs.readFileSync(file, "utf8");
    return { file, relative: path.relative(appDir, file), text };
  });

const layout = sourceText.find((item) => item.relative === "src/app/layout.tsx");
if (layout) {
  for (const requiredToken of [
    "EazoProvider",
    "I18nProvider",
    "UserSyncEffect",
    "NEXT_PUBLIC_APP_TITLE",
    "NEXT_PUBLIC_APP_DESCRIPTION",
  ]) {
    if (!layout.text.includes(requiredToken)) {
      add(
        "missing_template_shell",
        `src/app/layout.tsx must preserve ${requiredToken}`,
        "src/app/layout.tsx",
      );
    }
  }
}

const envExamplePath = path.join(appDir, ".env.example");
if (!fs.existsSync(envExamplePath)) {
  add("missing_env_documentation", "Missing .env.example", ".env.example");
} else {
  const envExample = fs.readFileSync(envExamplePath, "utf8");
  for (const variable of [
    "EAZO_PRIVATE_KEY",
    "EAZO_APP_ID",
    "NEXT_PUBLIC_APP_TITLE",
    "NEXT_PUBLIC_APP_DESCRIPTION",
  ]) {
    if (!envExample.includes(variable)) {
      add(
        "missing_env_documentation",
        `.env.example must document ${variable}`,
        ".env.example",
      );
    }
  }
}

for (const envName of [".env", ".env.local", ".env.production", ".env.development"]) {
  const envPath = path.join(appDir, envName);
  if (!fs.existsSync(envPath)) continue;
  const envText = fs.readFileSync(envPath, "utf8");
  if (/EAZO_PRIVATE_KEY\s*=\s*[0-9a-fA-F]{64}\b/.test(envText)) {
    add("committed_secret", `${envName} contains an Eazo private key`, envName);
  }
}

for (const item of sourceText) {
  const isClient = /(?:^|\n)\s*["']use client["'];?/.test(item.text);
  const importsAi =
    /import\s*\{[^}]*\bai\b[^}]*\}\s*from\s*["']@eazo\/sdk["']/.test(item.text) ||
    /import\s+ai\s+from\s*["']@eazo\/sdk["']/.test(item.text) ||
    /import\s+\*\s+as\s+\w+\s+from\s*["']@eazo\/sdk["'][\s\S]*?\.\s*ai\b/.test(item.text) ||
    /import\s*\(\s*["']@eazo\/sdk["']\s*\)[\s\S]*?\.\s*ai\b/.test(item.text);
  if (isClient && importsAi) {
    add(
      "client_ai_import",
      "Client components must not import Eazo ai",
      item.relative,
    );
  }

  if (item.relative.startsWith("src/app/api/") && importsAi && !item.text.includes("requireAuth")) {
    add(
      "unguarded_ai_route",
      "API routes using Eazo ai must call requireAuth",
      item.relative,
    );
  }

  const deadPatterns = [
    { regex: /href\s*=\s*["']#["']/, label: 'href="#"' },
    { regex: /onClick\s*=\s*\{\s*\(\s*\)\s*=>\s*\{\s*\}\s*\}/, label: "empty onClick handler" },
    { regex: /onClick\s*=\s*\{\s*undefined\s*\}/, label: "undefined onClick handler" },
    { regex: /<button\b[^>]*>\s*<\/button>/is, label: "empty button" },
    { regex: /<button\b[^>]*>[\s\S]*?coming soon[\s\S]*?<\/button>/i, label: "Coming soon button" },
  ];
  for (const pattern of deadPatterns) {
    if (pattern.regex.test(item.text)) {
      add(
        "dead_or_placeholder_control",
        `Found ${pattern.label}; every control must have a real action`,
        item.relative,
      );
    }
  }
}

const interactionMap = fs.existsSync(path.join(appDir, "design/interaction-map.json"))
  ? readJson("design/interaction-map.json")
  : null;
if (interactionMap && Array.isArray(interactionMap.controls)) {
  for (const control of interactionMap.controls) {
    if (!control || typeof control.id !== "string" || !control.id.trim()) {
      add("invalid_control_id", "Every interaction-map control needs a non-empty id", "design/interaction-map.json");
      continue;
    }
    const escapedId = control.id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const attributePattern = new RegExp(
      `data-control-id\\s*=\\s*["']${escapedId}["']`,
    );
    const candidates = [];
    for (const item of sourceText) {
      const openingTags = item.text.match(/<[A-Za-z][\w.]*\b[^>]*>/gs) ?? [];
      for (const openingTag of openingTags) {
        if (attributePattern.test(openingTag)) {
          candidates.push({ item, openingTag });
        }
      }
    }
    if (candidates.length === 0) {
      add(
        "missing_control_implementation",
        `Interaction control id is not rendered as a literal data-control-id: ${control.id}`,
        "design/interaction-map.json",
      );
      continue;
    }
    const hasInteractiveCandidate = candidates.some(({ openingTag }) => {
      const tagMatch = openingTag.match(/^<([A-Za-z][\w.]*)\b/);
      const tag = tagMatch ? tagMatch[1] : "";
      const lowerTag = tag.toLowerCase();
      if (["input", "select", "textarea"].includes(lowerTag)) return true;
      if (lowerTag === "a") return /\bhref\s*=/.test(openingTag) && !/href\s*=\s*["']#["']/.test(openingTag);
      if (lowerTag === "button" || /^[A-Z]/.test(tag)) {
        return /\b(onClick|onSubmit|formAction|href)\s*=/.test(openingTag) ||
          /\btype\s*=\s*["']submit["']/.test(openingTag);
      }
      return /\b(role\s*=\s*["']button["'][^>]*\bonClick|onClick[^>]*role\s*=\s*["']button["'])/.test(openingTag);
    });
    if (!hasInteractiveCandidate) {
      add(
        "noninteractive_control_mapping",
        `Control ${control.id} is attached only to non-interactive markup`,
        candidates[0].item.relative,
      );
    }
  }
}

fs.writeFileSync(outputPath, JSON.stringify({ findings }, null, 2) + "\n");
NODE

set +e
(
  cd "$APP_DIR"
  bun run lint
) >"$LINT_LOG" 2>&1
LINT_EXIT=$?

(
  cd "$APP_DIR"
  bun run build
) >"$BUILD_LOG" 2>&1
BUILD_EXIT=$?
set -e

node - "$STATIC_RESULT" "$APP_DIR/review/verification.json" "$LINT_EXIT" "$BUILD_EXIT" <<'NODE'
const fs = require("node:fs");

const staticResult = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const outputPath = process.argv[3];
const lintExit = Number(process.argv[4]);
const buildExit = Number(process.argv[5]);
const findings = [...staticResult.findings];

if (lintExit !== 0) {
  findings.push({
    severity: "blocking",
    code: "lint_failed",
    message: `bun run lint exited ${lintExit}`,
    file: "review/lint.log",
  });
}
if (buildExit !== 0) {
  findings.push({
    severity: "blocking",
    code: "build_failed",
    message: `bun run build exited ${buildExit}`,
    file: "review/build.log",
  });
}

const payload = {
  schema_version: "1.0",
  status: findings.length === 0 ? "pass" : "fail",
  commands: [
    { name: "lint", command: "bun run lint", exit_code: lintExit, log: "review/lint.log" },
    { name: "build", command: "bun run build", exit_code: buildExit, log: "review/build.log" },
  ],
  findings,
};
fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2) + "\n");
NODE

node - "$APP_DIR/review/verification.json" <<'NODE'
const fs = require("node:fs");
const result = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
if (result.status !== "pass") {
  for (const finding of result.findings) {
    process.stderr.write(`[${finding.code}] ${finding.message}${finding.file ? ` (${finding.file})` : ""}\n`);
  }
  process.exit(1);
}
NODE
