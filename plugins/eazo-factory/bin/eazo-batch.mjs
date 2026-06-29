#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";

const CLI_VERSION = "0.1.0";

function usage(exitCode = 0) {
  const text = `
Eazo Factory Batch CLI ${CLI_VERSION}

Usage:
  eazo-batch run <links.txt|jobs.json> [options]

Options:
  --out <dir>                 Output root. Default: ./eazo-batch-runs
  --concurrency <n>           Parallel codex workers. Default: 2
  --limit <n>                 Run only the first n jobs
  --dry-run                   Create prompts/report without launching codex
  --style <text>              Shared visual/style direction for every job
  --extra <text>              Extra instruction appended to every job prompt
  --codex-bin <path>          Codex executable. Default: codex
  --sandbox <mode>            codex exec sandbox. Default: workspace-write
  --approval <policy>         codex exec approval policy. Default: never
  --model <model>             Optional model passed to codex exec
  --yes                       Allow high concurrency without confirmation
  --help                      Show this help

Input:
  links.txt                   One URL/source per line; blank lines and # comments ignored
  jobs.json                   Array of strings or objects:
                              {"name","source"|"url"|"link","style","notes","screenshots":[]}
`;
  console.log(text.trim());
  process.exit(exitCode);
}

function fail(message, exitCode = 1) {
  console.error(`eazo-batch: ${message}`);
  process.exit(exitCode);
}

function parseArgs(argv) {
  const [command, input, ...rest] = argv;
  if (!command || command === "--help" || command === "-h") usage(0);
  if (command !== "run") fail(`unknown command "${command}"`);
  if (!input || input.startsWith("-")) fail("missing input file");

  const options = {
    input,
    out: path.resolve(process.cwd(), "eazo-batch-runs"),
    concurrency: 2,
    limit: null,
    dryRun: false,
    style: "",
    extra: "",
    codexBin: "codex",
    sandbox: "workspace-write",
    approval: "never",
    model: "",
    yes: false,
  };

  for (let index = 0; index < rest.length; index += 1) {
    let token = rest[index];
    let value = null;
    if (token.includes("=")) {
      const parts = token.split("=");
      token = parts.shift();
      value = parts.join("=");
    }

    const readValue = () => {
      if (value !== null) return value;
      index += 1;
      if (index >= rest.length) fail(`missing value for ${token}`);
      return rest[index];
    };

    switch (token) {
      case "--out":
        options.out = path.resolve(readValue());
        break;
      case "--concurrency":
        options.concurrency = parsePositiveInt(readValue(), "--concurrency");
        break;
      case "--limit":
        options.limit = parsePositiveInt(readValue(), "--limit");
        break;
      case "--style":
        options.style = readValue();
        break;
      case "--extra":
        options.extra = readValue();
        break;
      case "--codex-bin":
        options.codexBin = readValue();
        break;
      case "--sandbox":
        options.sandbox = readValue();
        break;
      case "--approval":
        options.approval = readValue();
        break;
      case "--model":
        options.model = readValue();
        break;
      case "--dry-run":
        options.dryRun = true;
        break;
      case "--yes":
        options.yes = true;
        break;
      case "--help":
      case "-h":
        usage(0);
        break;
      default:
        fail(`unknown option "${token}"`);
    }
  }

  if (options.concurrency > 5 && !options.yes) {
    fail("concurrency above 5 can burn a lot of tokens; rerun with --yes if intended");
  }

  return options;
}

function parsePositiveInt(raw, flag) {
  const value = Number.parseInt(raw, 10);
  if (!Number.isInteger(value) || value < 1) fail(`${flag} must be a positive integer`);
  return value;
}

function readJobs(inputPath) {
  const absoluteInput = path.resolve(inputPath);
  if (!fs.existsSync(absoluteInput)) fail(`input file not found: ${absoluteInput}`);
  const ext = path.extname(absoluteInput).toLowerCase();
  const inputDir = path.dirname(absoluteInput);
  const raw = fs.readFileSync(absoluteInput, "utf8");

  if (ext === ".json") {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) fail("jobs.json must be an array");
    return parsed.map((item, index) => normalizeJob(item, index, inputDir));
  }

  return raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#"))
    .map((source, index) => normalizeJob(source, index, inputDir));
}

function normalizeJob(item, index, inputDir) {
  if (typeof item === "string") {
    return {
      index,
      source: item.trim(),
      name: "",
      style: "",
      notes: "",
      screenshots: [],
    };
  }
  if (!item || typeof item !== "object" || Array.isArray(item)) {
    fail(`job ${index + 1} must be a string or object`);
  }
  const source = item.source || item.url || item.link;
  if (!source || typeof source !== "string") {
    fail(`job ${index + 1} is missing source/url/link`);
  }
  const screenshots = Array.isArray(item.screenshots)
    ? item.screenshots.map((imagePath) => path.resolve(inputDir, String(imagePath)))
    : [];
  for (const imagePath of screenshots) {
    if (!fs.existsSync(imagePath)) fail(`job ${index + 1} screenshot not found: ${imagePath}`);
  }
  return {
    index,
    source: source.trim(),
    name: item.name ? String(item.name) : "",
    style: item.style ? String(item.style) : "",
    notes: item.notes ? String(item.notes) : "",
    screenshots,
  };
}

function timestamp() {
  const date = new Date();
  const pad = (value) => String(value).padStart(2, "0");
  return [
    date.getFullYear(),
    pad(date.getMonth() + 1),
    pad(date.getDate()),
    "-",
    pad(date.getHours()),
    pad(date.getMinutes()),
    pad(date.getSeconds()),
  ].join("");
}

function slugify(value, fallback) {
  const cleaned = value
    .toLowerCase()
    .replace(/^https?:\/\//, "")
    .replace(/[^a-z0-9\u4e00-\u9fff]+/gi, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 56);
  return cleaned || fallback;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJson(file, data) {
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
}

function makePrompt(job, options, paths) {
  const style = [options.style, job.style].filter(Boolean).join("；");
  const lines = [
    "@eazo-factory 批量模式：请为下面这个来源生成一个独立、可预览的 Eazo App。",
    "",
    `来源: ${job.source}`,
    `输出目录必须使用: ${paths.appDir}`,
    "",
    "批量模式要求：",
    "- 不要进入长时间交互式追问；信息足够时直接做合理产品判断。",
    "- 如果来源被小红书登录/验证墙挡住，并且截图或文本不足，请停止该 job，并在最终消息写明 needs_input: 需要用户登录小红书后重试或补充截图。",
    "- 每个 app 必须彼此独立，不要复用其他 job 的 staging 目录。",
    "- 仍然执行 Eazo Factory 标准：source intake / UI素材板 / 官方模板开发 / 验证 / 独立 review / 本地 preview。",
    "- 所有 app 必须带中英文切换；体验类 app 要有匹配 BGM；所有按钮必须可用，不要放无效按钮。",
  ];
  if (style) lines.push(`- 统一视觉方向: ${style}`);
  if (job.notes) lines.push(`- 本 job 额外说明: ${job.notes}`);
  if (options.extra) lines.push(`- 全局额外说明: ${options.extra}`);
  if (job.screenshots.length > 0) {
    lines.push("");
    lines.push("随命令附带的 --image 截图是该 job 的视觉/内容参考，请作为 source material 处理。");
  }
  return `${lines.join("\n")}\n`;
}

function initialReport(options, batchDir, inputPath, jobs) {
  return {
    version: 1,
    cliVersion: CLI_VERSION,
    mode: options.dryRun ? "dry-run" : "run",
    createdAt: new Date().toISOString(),
    inputPath,
    batchDir,
    options: {
      concurrency: options.concurrency,
      sandbox: options.sandbox,
      approval: options.approval,
      model: options.model || null,
      style: options.style || null,
      extra: options.extra || null,
    },
    summary: {
      total: jobs.length,
      pending: jobs.length,
      running: 0,
      succeeded: 0,
      failed: 0,
      dryRun: 0,
    },
    jobs: [],
  };
}

function summarize(report) {
  const counts = { pending: 0, running: 0, succeeded: 0, failed: 0, dryRun: 0 };
  for (const job of report.jobs) {
    if (job.status === "pending") counts.pending += 1;
    if (job.status === "running") counts.running += 1;
    if (job.status === "success") counts.succeeded += 1;
    if (job.status === "failed") counts.failed += 1;
    if (job.status === "dry_run") counts.dryRun += 1;
  }
  report.summary = { total: report.jobs.length, ...counts };
}

function extractPreviewUrl(finalPath) {
  if (!fs.existsSync(finalPath)) return null;
  const text = fs.readFileSync(finalPath, "utf8");
  return text.match(/https?:\/\/(?:localhost|127\.0\.0\.1):\d+[^\s)]*/)?.[0] || null;
}

async function runJob(job, options, context, report) {
  const id = String(job.index + 1).padStart(3, "0");
  const slug = `${id}-${slugify(job.name || job.source, `job-${id}`)}`;
  const jobDir = path.join(context.batchDir, "jobs", slug);
  const appDir = path.join(context.batchDir, "apps", slug);
  const paths = {
    jobDir,
    appDir,
    promptPath: path.join(jobDir, "prompt.txt"),
    finalPath: path.join(jobDir, "final.md"),
    stdoutPath: path.join(jobDir, "stdout.log"),
    stderrPath: path.join(jobDir, "stderr.log"),
    statusPath: path.join(jobDir, "status.json"),
  };
  ensureDir(jobDir);
  ensureDir(appDir);

  const prompt = makePrompt(job, options, paths);
  fs.writeFileSync(paths.promptPath, prompt);

  const status = {
    id,
    name: job.name || null,
    source: job.source,
    status: options.dryRun ? "dry_run" : "running",
    appDir,
    jobDir,
    promptPath: paths.promptPath,
    finalMessagePath: paths.finalPath,
    stdoutLogPath: paths.stdoutPath,
    stderrLogPath: paths.stderrPath,
    screenshots: job.screenshots,
    startedAt: new Date().toISOString(),
    finishedAt: null,
    durationMs: null,
    exitCode: null,
    previewUrl: null,
  };
  report.jobs[job.index] = status;
  summarize(report);
  writeJson(context.reportPath, report);
  writeJson(paths.statusPath, status);

  if (options.dryRun) {
    status.finishedAt = new Date().toISOString();
    status.durationMs = 0;
    writeJson(paths.statusPath, status);
    summarize(report);
    writeJson(context.reportPath, report);
    return status;
  }

  const started = Date.now();
  const args = [
    "exec",
    "--cd",
    context.batchDir,
    "--skip-git-repo-check",
    "--sandbox",
    options.sandbox,
    "--ask-for-approval",
    options.approval,
    "--output-last-message",
    paths.finalPath,
  ];
  if (options.model) args.push("--model", options.model);
  for (const imagePath of job.screenshots) args.push("--image", imagePath);
  args.push(prompt);

  fs.writeFileSync(paths.stdoutPath, "");
  fs.writeFileSync(paths.stderrPath, "");
  fs.writeFileSync(path.join(jobDir, "codex-args.json"), `${JSON.stringify(args, null, 2)}\n`);

  const exitCode = await new Promise((resolve) => {
    const child = spawn(options.codexBin, args, {
      cwd: context.batchDir,
      stdio: ["ignore", "pipe", "pipe"],
    });
    child.stdout.on("data", (chunk) => {
      process.stdout.write(`[${id}] ${chunk}`);
      fs.appendFileSync(paths.stdoutPath, chunk);
    });
    child.stderr.on("data", (chunk) => {
      process.stderr.write(`[${id}] ${chunk}`);
      fs.appendFileSync(paths.stderrPath, chunk);
    });
    child.on("error", (error) => {
      fs.appendFileSync(paths.stderrPath, `${error.stack || error.message}\n`);
      resolve(127);
    });
    child.on("close", resolve);
  });

  status.exitCode = exitCode;
  status.status = exitCode === 0 ? "success" : "failed";
  status.finishedAt = new Date().toISOString();
  status.durationMs = Date.now() - started;
  status.previewUrl = extractPreviewUrl(paths.finalPath);
  writeJson(paths.statusPath, status);
  summarize(report);
  writeJson(context.reportPath, report);
  return status;
}

async function runQueue(jobs, concurrency, worker) {
  let nextIndex = 0;
  const workers = Array.from({ length: Math.min(concurrency, jobs.length) }, async () => {
    while (nextIndex < jobs.length) {
      const job = jobs[nextIndex];
      nextIndex += 1;
      await worker(job);
    }
  });
  await Promise.all(workers);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const inputPath = path.resolve(options.input);
  let jobs = readJobs(inputPath);
  if (options.limit) jobs = jobs.slice(0, options.limit);
  if (jobs.length === 0) fail("input produced zero jobs");

  const batchDir = path.join(options.out, `batch-${timestamp()}`);
  const reportPath = path.join(batchDir, "batch-report.json");
  ensureDir(path.join(batchDir, "jobs"));
  ensureDir(path.join(batchDir, "apps"));

  const report = initialReport(options, batchDir, inputPath, jobs);
  writeJson(reportPath, report);

  console.log(`Eazo batch ${options.dryRun ? "dry-run" : "run"} started`);
  console.log(`jobs: ${jobs.length}, concurrency: ${options.concurrency}`);
  console.log(`batch: ${batchDir}`);
  console.log(`report: ${reportPath}`);

  await runQueue(jobs, options.concurrency, (job) =>
    runJob(job, options, { batchDir, reportPath }, report),
  );

  summarize(report);
  writeJson(reportPath, report);
  console.log(`Eazo batch finished: ${JSON.stringify(report.summary)}`);
  console.log(`Report: ${reportPath}`);
  process.exit(report.summary.failed > 0 ? 1 : 0);
}

main().catch((error) => fail(error.stack || error.message));
