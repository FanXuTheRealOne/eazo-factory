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

function stripComments(text) {
  return text
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/(^|[^:])\/\/.*$/gm, "$1");
}

function unique(values) {
  return [...new Set(values)];
}

function crc32(buffer) {
  let crc = 0xffffffff;
  for (const byte of buffer) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function validPng(image) {
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (image.length < 45 || !image.subarray(0, 8).equals(signature)) return false;
  let offset = 8;
  let chunkCount = 0;
  let sawIhdr = false;
  let sawIdat = false;
  let sawIend = false;
  while (offset + 12 <= image.length) {
    const length = image.readUInt32BE(offset);
    const end = offset + 12 + length;
    if (end > image.length) return false;
    const type = image.subarray(offset + 4, offset + 8);
    const data = image.subarray(offset + 8, offset + 8 + length);
    const expectedCrc = image.readUInt32BE(offset + 8 + length);
    if (crc32(Buffer.concat([type, data])) !== expectedCrc) return false;
    const typeName = type.toString("ascii");
    if (chunkCount === 0) {
      if (typeName !== "IHDR" || length !== 13) return false;
      if (data.readUInt32BE(0) === 0 || data.readUInt32BE(4) === 0) return false;
      sawIhdr = true;
    }
    if (typeName === "IDAT") sawIdat = true;
    if (typeName === "IEND") {
      if (length !== 0 || end !== image.length) return false;
      sawIend = true;
      offset = end;
      break;
    }
    offset = end;
    chunkCount += 1;
  }
  return sawIhdr && sawIdat && sawIend && offset === image.length;
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
  if (!validPng(image)) {
    add("invalid_ui_reference", "design/ui-reference.png must be a real PNG image", "design/ui-reference.png");
  }
}

const run = fs.existsSync(path.join(appDir, "factory-run.json"))
  ? readJson("factory-run.json")
  : null;
if (run && (!run.starter || !/^[0-9a-f]{40}$/.test(run.starter.commit ?? ""))) {
  add("missing_starter_commit", "factory-run.json starter.commit must be a full 40-character Git commit", "factory-run.json");
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
    return { file, relative: path.relative(appDir, file), text, clean: stripComments(text) };
  });
const sourceByFile = new Map(sourceText.map((item) => [item.file, item]));

function resolveImport(fromFile, specifier) {
  let base;
  if (specifier.startsWith("@/")) base = path.join(sourceRoot, specifier.slice(2));
  else if (specifier.startsWith(".")) base = path.resolve(path.dirname(fromFile), specifier);
  else return null;
  for (const candidate of [
    base,
    ...[".ts", ".tsx", ".js", ".jsx"].map((extension) => `${base}${extension}`),
    ...["index.ts", "index.tsx", "index.js", "index.jsx"].map((name) => path.join(base, name)),
  ]) {
    if (sourceByFile.has(candidate)) return candidate;
  }
  return null;
}

function importedFiles(item) {
  const imports = [];
  const pattern = /(?:import|export)\s+(?:[\s\S]*?\s+from\s+)?["']([^"']+)["']|import\s*\(\s*["']([^"']+)["']\s*\)/g;
  let match;
  while ((match = pattern.exec(item.clean))) {
    const resolved = resolveImport(item.file, match[1] ?? match[2]);
    if (resolved) imports.push(resolved);
  }
  return unique(imports);
}

const dependencies = new Map(sourceText.map((item) => [item.file, importedFiles(item)]));
const entryFiles = sourceText
  .filter((item) => /^src\/app\/.*(?:page|layout|error|not-found|loading)\.[cm]?[jt]sx?$/.test(item.relative))
  .map((item) => item.file);
const reachableFiles = new Set();
const pendingFiles = [...entryFiles];
while (pendingFiles.length) {
  const current = pendingFiles.pop();
  if (!current || reachableFiles.has(current)) continue;
  reachableFiles.add(current);
  pendingFiles.push(...(dependencies.get(current) ?? []));
}

const layout = sourceText.find((item) => item.relative === "src/app/layout.tsx");
if (layout) {
  const requiredLayoutPatterns = [
    [/\bimport\s*\{\s*EazoProvider\s*\}\s*from\s*["']@eazo\/sdk\/react["']/, "official EazoProvider import"],
    [/\bimport\s*\{\s*I18nProvider\s*\}\s*from\s*["']@\/components\/i18n\/i18n-provider["']/, "official I18nProvider import"],
    [/\bimport\s*\{\s*UserSyncEffect\s*\}\s*from\s*["']@\/components\/user-profile\/user-sync-effect["']/, "official UserSyncEffect import"],
    [/\bprocess\.env\.NEXT_PUBLIC_APP_TITLE\b/, "NEXT_PUBLIC_APP_TITLE metadata"],
    [/\bprocess\.env\.NEXT_PUBLIC_APP_DESCRIPTION\b/, "NEXT_PUBLIC_APP_DESCRIPTION metadata"],
    [/<I18nProvider\b[\s\S]*<EazoProvider\b[\s\S]*<UserSyncEffect\b/, "official provider nesting"],
  ];
  for (const [pattern, label] of requiredLayoutPatterns) {
    if (!pattern.test(layout.clean)) {
      add(
        "missing_template_shell",
        `src/app/layout.tsx must preserve ${label}`,
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

function directlyUsesAi(item) {
  return /import\s*\{[^}]*\bai(?:\s+as\s+\w+)?\b[^}]*\}\s*from\s*["']@eazo\/sdk["']/.test(item.clean) ||
    /import\s+\*\s+as\s+(\w+)\s+from\s*["']@eazo\/sdk["'][\s\S]*?\b\1\.ai\b/.test(item.clean) ||
    /import\s*\(\s*["']@eazo\/sdk["']\s*\)[\s\S]*?\.ai\b/.test(item.clean);
}

function dependencyClosure(startFile) {
  const result = new Set();
  const queue = [startFile];
  while (queue.length) {
    const current = queue.pop();
    if (!current || result.has(current)) continue;
    result.add(current);
    queue.push(...(dependencies.get(current) ?? []));
  }
  return result;
}

function exportedRouteHandlerBodies(text) {
  const bodies = [];
  const pattern = /export\s+(?:async\s+)?function\s+(GET|POST|PUT|PATCH|DELETE)\s*\([^)]*\)\s*\{/g;
  let match;
  while ((match = pattern.exec(text))) {
    const bodyStart = pattern.lastIndex;
    let depth = 1;
    let cursor = bodyStart;
    while (cursor < text.length && depth > 0) {
      if (text[cursor] === "{") depth += 1;
      else if (text[cursor] === "}") depth -= 1;
      cursor += 1;
    }
    if (depth === 0) bodies.push({ method: match[1], body: text.slice(bodyStart, cursor - 1) });
  }
  return bodies;
}

for (const item of sourceText) {
  const isClient = /(?:^|\n)\s*["']use client["'];?/.test(item.clean);
  const closure = dependencyClosure(item.file);
  const usesAi = [...closure].some((file) => directlyUsesAi(sourceByFile.get(file)));
  if (isClient && usesAi) {
    add(
      "client_ai_import",
      "Client components must not import Eazo ai directly or transitively",
      item.relative,
    );
  }

  if (/^src\/app\/api\/.*\/route\.[cm]?[jt]s$/.test(item.relative) && usesAi) {
    const authImport = item.clean.match(
      /import\s*\{([^}]*)\}\s*from\s*["']@eazo\/sdk["']/,
    );
    const requireAuthBinding = authImport?.[1]
      ?.split(",")
      .map((part) => part.trim())
      .map((part) => part.match(/^requireAuth(?:\s+as\s+(\w+))?$/))
      .find(Boolean);
    const authName = requireAuthBinding ? (requireAuthBinding[1] || "requireAuth") : null;
    const handlers = exportedRouteHandlerBodies(item.clean);
    const everyHandlerAuthenticated = handlers.length > 0 &&
      handlers.every(({ body }) => authName && new RegExp(`\\b${authName}\\s*\\(`).test(body));
    if (!everyHandlerAuthenticated) {
      add(
        "unguarded_ai_route",
        "Every exported handler in an API route using Eazo ai must import and call requireAuth inside the handler",
        item.relative,
      );
    }
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
const sourceControlInventory = [];
for (const item of sourceText.filter((candidate) => reachableFiles.has(candidate.file))) {
  if (item.relative.startsWith("src/components/ui/")) continue;
  const openingTags = item.clean.match(/<[A-Za-z][\w.:-]*\b[^>]*>/gs) ?? [];
  for (const openingTag of openingTags) {
    const tag = openingTag.match(/^<([A-Za-z][\w.:-]*)\b/)?.[1] ?? "";
    const lowerTag = tag.toLowerCase();
    const nativeInteractive =
      lowerTag === "button" ||
      ["input", "select", "textarea"].includes(lowerTag) ||
      (lowerTag === "a" && /\bhref\s*=/.test(openingTag));
    const explicitInteractive =
      /\b(onClick|onSubmit|formAction|href)\s*=/.test(openingTag) ||
      /\btype\s*=\s*["']submit["']/.test(openingTag) ||
      /\brole\s*=\s*["']button["']/.test(openingTag);
    const namedInteractive = /(?:Button|Link|Toggle|Switch|Tab|Select|Input|Textarea|Checkbox|Radio|MenuItem)$/.test(tag);
    if (!nativeInteractive && !explicitInteractive && !namedInteractive) continue;
    const productId = openingTag.match(/\bdata-control-id\s*=\s*["']([^"']+)["']/)?.[1] ?? null;
    const sdkId = openingTag.match(/\bdata-eazo-sdk-control\s*=\s*["']([^"']+)["']/)?.[1] ?? null;
    if ((productId && sdkId) || (!productId && !sdkId)) {
      add(
        "unmapped_source_control",
        "Every reachable interactive element must declare exactly one literal data-control-id or data-eazo-sdk-control",
        item.relative,
      );
      continue;
    }
    sourceControlInventory.push({
      owner: productId ? "product" : "eazo_sdk",
      id: productId ?? sdkId,
      file: item.relative,
    });
  }
}

if (!interactionMap || interactionMap.schema_version !== "1.0" || !Array.isArray(interactionMap.controls)) {
  add("invalid_interaction_map", "interaction-map.json must use schema_version 1.0 and a controls array", "design/interaction-map.json");
} else if (interactionMap.controls.length === 0) {
  add("empty_interaction_map", "interaction-map.json must define at least one product control", "design/interaction-map.json");
} else {
  const mapIds = interactionMap.controls
    .map((control) => control?.id)
    .filter((id) => typeof id === "string" && id.trim());
  const sourceProductIds = unique(
    sourceControlInventory.filter((control) => control.owner === "product").map((control) => control.id),
  );
  if (unique(mapIds).length !== mapIds.length) {
    add("duplicate_control_id", "interaction-map control IDs must be unique", "design/interaction-map.json");
  }
  for (const extraId of sourceProductIds.filter((id) => !mapIds.includes(id))) {
    add("extra_source_control", `Source control is not declared in interaction-map.json: ${extraId}`);
  }
  for (const missingId of mapIds.filter((id) => !sourceProductIds.includes(id))) {
    add("missing_control_implementation", `Interaction control is not rendered: ${missingId}`, "design/interaction-map.json");
  }
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

fs.writeFileSync(
  outputPath,
  JSON.stringify({ findings, source_control_inventory: sourceControlInventory }, null, 2) + "\n",
);
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
  source_control_inventory: staticResult.source_control_inventory ?? [],
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
