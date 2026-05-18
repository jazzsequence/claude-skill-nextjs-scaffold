# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code skill packaged as an installable plugin that scaffolds a Pantheon Content Publisher + Next.js site end to end. This is **not** a Next.js project — it is a skill/plugin definition repo. The scaffolded project lives elsewhere after the skill runs.

## Files

- **`skills/scaffold-cpub-nextjs/SKILL.md`** — The skill definition. This is what Claude reads and executes when `/scaffold-cpub-nextjs` is invoked. Written as imperative instructions.
- **`.claude-plugin/marketplace.json`** — Marketplace manifest. Registers this repo as a Claude Code plugin source with version and owner metadata.
- **`.claude-plugin/plugin.json`** — Plugin manifest. Name, version, author.
- **`install.sh`** — Installer script. Merges the plugin into `~/.claude/settings.json` using Node.js. No external dependencies required.
- **`README.md`** — Human-facing documentation: installation, usage, prerequisites.

## Maintaining this skill

When editing `skills/scaffold-cpub-nextjs/SKILL.md`:
- Keep instructions imperative — written for Claude to execute, not for a human to read
- Commands must be verified against the actual CLIs (`cpub`, `terminus`, `gh`) before updating
- The `nextjs-16` upstream UUID (`f9c1a10c-bd05-448f-9c0d-b73839e69e58`) and the `--type=env --scope=web` secret flags are non-obvious and were validated by running the full workflow — do not change without re-testing
- The `--rebuild` flag on `terminus secret:site:set` triggers a PHP fatal error in the current Terminus version — do not add it back
- Background `site:create` and poll for site existence before setting secrets — this ensures the first build fires with secrets already in place

When editing `README.md`:
- Installation is via `install.sh` — update that script if the plugin registration mechanism changes, then update the README to match

## Versioning

**Always bump the version in both `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` when making changes to the skill.** The plugin system compares version numbers to determine if an update is available — if the version never changes, `claude plugin update` will always report "already at the latest version" even when the skill content has changed.

Use semantic versioning:
- `patch` (e.g. `2.0.0` → `2.0.1`) — bug fixes, wording corrections, minor additions
- `minor` (e.g. `2.0.0` → `2.1.0`) — new skill steps, new features
- `major` (e.g. `2.0.0` → `3.0.0`) — breaking changes to the workflow or interface
