# Eazo Factory

Generate one polished, bilingual, independently reviewed Eazo app from a product prompt using Codex and the official Eazo Next.js template.

## Install from GitHub

The intended public repository is `EazoAI/eazo-factory`:

```bash
codex plugin marketplace add EazoAI/eazo-factory
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

The workflow produces a product specification, `$imagegen` UI reference board, reusable asset library, interaction map, official-template implementation, deterministic verification, independent browser review, control audit, and local preview.

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
