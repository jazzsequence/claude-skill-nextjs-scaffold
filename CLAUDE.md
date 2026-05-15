# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code skill that scaffolds a Pantheon Content Publisher + Next.js site end to end. This is **not** a Next.js project — it is a skill definition repo. The scaffolded project lives elsewhere after the skill runs.

## Files

- **`skill.md`** — The skill definition. This is what Claude reads and executes when `/scaffold-cpub-nextjs` is invoked. Written as imperative instructions.
- **`README.md`** — Human-facing documentation: installation, usage, prerequisites.

## Maintaining this skill

When editing `skill.md`:
- Keep instructions imperative — written for Claude to execute, not for a human to read
- Commands must be verified against the actual CLIs (`cpub`, `terminus`, `gh`) before updating
- The `nextjs-16` upstream UUID (`f9c1a10c-bd05-448f-9c0d-b73839e69e58`) and the `--type=env --scope=web` secret flags are non-obvious and were validated by running the full workflow — do not change without re-testing
- The `--rebuild` flag on `terminus secret:site:set` triggers a PHP fatal error in the current Terminus version — do not add it back

When editing `README.md`:
- Installation instructions assume a local `~/.claude/skills/` directory — update if the skill registration mechanism changes
