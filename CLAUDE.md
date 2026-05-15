# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Next.js 16 + TypeScript site scaffolded from the [Pantheon Content Publisher starter](https://github.com/pantheon-systems/content-publisher-sdk/tree/main/starters/nextjs-starter-approuter-ts), deployed on Pantheon's Next.js hosting, and pulling content from Google Docs via the Content Publisher add-on.

---

## Scaffold a new site

Use this workflow to create a new Content Publisher + Next.js site on Pantheon. Replace `$SITE_NAME` with a lowercase, hyphens-only machine name and `$GITHUB_ORG` with a GitHub org or username.

### 1. Verify prerequisites

```bash
cpub whoami          # Content Publisher CLI
terminus auth:whoami # Terminus
gh auth status       # GitHub CLI
```

Install anything missing before continuing (see Prerequisites section below).

### 2. Scaffold the codebase

Run from the **parent** directory where you want the project created. `cpub init` fails if the target directory already exists — if you have prior files there (e.g. `CLAUDE.md`, `.claude/`), back up the whole directory first:

```bash
cp -r $SITE_NAME /tmp/$SITE_NAME-backup
rm -rf $SITE_NAME
```

Then scaffold:

```bash
cpub init $SITE_NAME --ts --eslint --appRouter --non-interactive
```

This scaffolds into a new `$SITE_NAME/` directory from the `nextjs-starter-approuter-ts` starter. Restore any backed-up files afterward (`CLAUDE.md`, `.claude/`, etc.).

### 3. Initialize git

```bash
cd $SITE_NAME
git init
git add .
git commit -m "Initial commit: Content Publisher Next.js starter"
```

### 4. Create a GitHub repo and push

```bash
# With an org:
gh repo create $GITHUB_ORG/$SITE_NAME --private --source=. --remote=origin --push

# Personal account only:
gh repo create $SITE_NAME --private --source=. --remote=origin --push
```

Confirm: `gh repo view $SITE_NAME --json url -q .url`

### 5. Create the Pantheon site

```bash
terminus site:create $SITE_NAME "$SITE_NAME" --framework=nextjs
```

Then connect the GitHub repo via the **Pantheon Dashboard > Settings > Source Code**. CLI-based GitHub connection is not supported via Terminus. The dashboard connection triggers the first build automatically.

### 6. Set Content Publisher secrets

Obtain `PCC_SITE_ID` and `PCC_TOKEN` from [content.pantheon.io](https://content.pantheon.io), then:

```bash
terminus secret:site:set $SITE_NAME PCC_SITE_ID "your-collection-id" --scope=ic
terminus secret:site:set $SITE_NAME PCC_TOKEN "your-token" --scope=ic
```

`--scope=ic` makes secrets available at image compile (build) time, which Content Publisher requires.

### 7. Verify the build

```bash
terminus build:log $SITE_NAME.dev
# or, if the Node Logs plugin is installed:
terminus node-log:stream $SITE_NAME.dev
```

The dev environment will be live at `https://dev-$SITE_NAME.pantheonsite.io`.

---

## Prerequisites

Three CLIs must be installed and authenticated before any Pantheon/GitHub operations:

```bash
cpub whoami          # install: npm install -g @pantheon-systems/cpub-cli
terminus auth:whoami # install: https://github.com/pantheon-systems/terminus
gh auth status       # install: brew install gh
```

## Development commands

```bash
npm run dev          # start dev server on port 3002 (Turbopack)
npm run build        # production build
npm run lint         # ESLint
npm run prettier     # check formatting
npm run prettier:fix # fix formatting
npm test             # run Vitest unit/snapshot tests (single run)
npm run test:watch   # Vitest in watch mode
npm run test:playwright  # Playwright E2E tests
npm run update-snapshots # update Vitest snapshots after presentational changes
```

## Environment variables

Copy `.env.example` to `.env.local` for local development:

```
PCC_SITE_ID=   # collection ID from content.pantheon.io
PCC_TOKEN=     # token from content.pantheon.io
```

On Pantheon, these are set as secrets (not env vars) so they're available at build time:

```bash
terminus secret:site:set $SITE_NAME PCC_SITE_ID "..." --scope=ic
terminus secret:site:set $SITE_NAME PCC_TOKEN "..."   --scope=ic
```

The `--scope=ic` flag is required — it makes secrets available at image compile (build) time.

## Architecture

**Routing:** Next.js App Router (`app/` directory).

**Content fetching:** `@pantheon-systems/cpub-react-sdk` handles all Content Publisher API calls. Content comes from Google Docs via the PCC add-on; `PCC_SITE_ID` and `PCC_TOKEN` identify which collection to pull from.

**Cache handler:** `cacheHandler.mjs` / `useCacheHandler.mjs` — file-based locally, GCS-backed on Pantheon. Configured in `next.config.js`. Don't modify the cache handler without understanding Pantheon's caching layer.

**Styling:** Tailwind CSS with `@tailwindcss/typography`. Config in `tailwind.config.cjs`.

**Testing:** Vitest for unit/snapshot tests (`__tests__/`), Playwright for E2E (`playwright-tests/`). Snapshot tests use `@testing-library/react`. Update snapshots when making presentational changes.

## Pantheon deployment

The Pantheon site is connected to this GitHub repo via the Pantheon Dashboard (**Settings > Source Code**). Pushing to `main` triggers a build automatically. The dev environment URL is `https://dev-{site-name}.pantheonsite.io`.

GitHub connection cannot be configured via Terminus — use the dashboard UI.

## Key references

- [Content Publisher docs](https://docs.content.pantheon.io)
- [Pantheon Next.js docs](https://docs.pantheon.io/nextjs)
- [Content Publisher tutorial](https://docs.pantheon.io/nextjs/content-publisher-tutorial)
