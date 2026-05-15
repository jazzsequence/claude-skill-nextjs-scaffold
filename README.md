# Claude Skill: Next.js Scaffold

A Claude Code skill that scaffolds a new [Pantheon Content Publisher](https://docs.content.pantheon.io) + Next.js site from zero to a live dev environment — codebase, GitHub repo, Pantheon site, secrets, and first build — in a single command.

## What it does

Invoking this skill walks Claude through:

1. Verifying a Content Publisher collection exists (and walking the user through creating one if not)
2. Checking all prerequisite CLIs are installed and authenticated
3. Scaffolding a Next.js 16 + TypeScript codebase from the official [`nextjs-starter-approuter-ts`](https://github.com/pantheon-systems/content-publisher-sdk/tree/main/starters/nextjs-starter-approuter-ts) starter
4. Initializing git and pushing to a new private GitHub repository
5. Creating a Pantheon Next.js site connected to that GitHub repo
6. Setting `PCC_SITE_ID` and `PCC_TOKEN` as Pantheon secrets
7. Triggering and monitoring the first build

## Installation

Copy `skill.md` into your Claude Code skills directory and register it:

```bash
mkdir -p ~/.claude/skills/scaffold-cpub-nextjs
cp skill.md ~/.claude/skills/scaffold-cpub-nextjs/skill.md
```

Then add it to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "skills": {
    "scaffold-cpub-nextjs": {
      "path": "~/.claude/skills/scaffold-cpub-nextjs/skill.md"
    }
  }
}
```

## Usage

```
/scaffold-cpub-nextjs <site-name> [github-org]
```

- `site-name` — machine name for the GitHub repo and Pantheon site (lowercase, hyphens only)
- `github-org` — GitHub org or username (defaults to your personal account)

## Prerequisites

The following must be installed and authenticated before invoking the skill. Claude will check and guide you through any that are missing.

| Tool | Install | Auth |
|---|---|---|
| [Content Publisher CLI](https://github.com/pantheon-systems/content-publisher-sdk) | `npm install -g @pantheon-systems/cpub-cli` | `cpub login` |
| [Terminus](https://github.com/pantheon-systems/terminus) | See install docs | `terminus auth:login` |
| [GitHub CLI](https://cli.github.com) | `brew install gh` | `gh auth login` |

You'll also need a [Content Publisher collection](https://content.pantheon.io) with a Collection ID and Token before the skill can complete. Claude will prompt you if these are missing.

## What you end up with

- A Next.js 16 + TypeScript codebase scaffolded from the official Content Publisher starter
- A private GitHub repo connected to a Pantheon Next.js site via the Pantheon GitHub App
- `PCC_SITE_ID` and `PCC_TOKEN` set as Pantheon secrets, available at both build and runtime
- A live dev environment at `https://dev-<site-name>.pantheonsite.io`

## Files

| File | Purpose |
|---|---|
| `skill.md` | The skill definition — imperative instructions Claude follows when the skill is invoked |
| `CLAUDE.md` | Guidance for Claude Code when working on this skill repo itself |
