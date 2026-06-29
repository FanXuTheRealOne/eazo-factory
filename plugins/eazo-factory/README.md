# Eazo Factory

Generate one polished, bilingual, independently reviewed Eazo app from a product prompt using Codex and the official Eazo Next.js template.

## Install from GitHub

The public repository is `FanXuTheRealOne/eazo-factory`:

```bash
codex plugin marketplace add FanXuTheRealOne/eazo-factory
codex plugin add eazo-factory@eazo-tools
```

Start a new Codex thread after installation.

## Install this local checkout

From the repository root:

```bash
codex plugin marketplace add .
codex plugin add eazo-factory@eazo-tools
```

## Use

```text
@eazo-factory Create a Matisse-inspired breathing meditation app.
```

You can also provide source material directly:

```text
@eazo-factory 从这个小红书链接复刻成一个 Eazo app: https://www.xiaohongshu.com/...
```

```text
@eazo-factory 按这几张小红书截图做成一个 Eazo app
```

For first-time help, invoke the plugin without an app brief:

```text
@eazo-factory 怎么用？
```

The plugin will show a visual onboarding card with a small flow illustration and example prompts instead of starting generation.

The workflow can extract a source brief from links or screenshots, then produces a product specification, `$imagegen` UI reference board, reusable asset library, interaction map, official-template implementation, deterministic verification, independent browser review, control audit, and local preview.

For the full bilingual project guide, see the repository root `README.md`.

## Requirements

- Codex with `$imagegen`
- Git
- Bun
- Node.js
- Network access to `https://github.com/EazoAI/eazo-creator-nextjs-template.git`
- Browser tooling for a passing visual and interaction review

## Pass conditions

An app cannot pass while any blocking bug, failed core flow, missing English/Chinese switch, missing required BGM, dead button, decorative control, unmapped interaction, or failed control audit remains. The independent reviewer must test every visible control.

## Safety

The plugin never deploys, publishes, pushes generated repositories, or commits secrets.
