# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Next.js 16 + TypeScript site scaffolded from the [Pantheon Content Publisher starter](https://github.com/pantheon-systems/content-publisher-sdk/tree/main/starters/nextjs-starter-approuter-ts), deployed on Pantheon's Next.js hosting, and pulling content from Google Docs via the Content Publisher add-on.

---

## Scaffold a new site

Use this workflow to create a new Content Publisher + Next.js site on Pantheon. Replace `$SITE_NAME` with a lowercase, hyphens-only machine name and `$GITHUB_ORG` with a GitHub org or username.

### 0. Create a Content Publisher collection

**This must exist before you begin.** The build will fail with "Missing Pantheon Content Publisher site ID" if secrets are not set, and secrets cannot be set without a collection.

1. Go to [content.pantheon.io](https://content.pantheon.io) and sign in
2. Navigate to **Collections** → **+ New collection**, select a Google account, set publishing permissions
3. Copy the **Collection ID** (`PCC_SITE_ID`) from the collection page
4. Navigate to **Tokens** (separate section in the left nav) → create a new token → copy it immediately (`PCC_TOKEN`) — tokens are only shown once

Ask the user to confirm they have both values before proceeding.

### 1. Verify prerequisites

```bash
cpub whoami          # Content Publisher CLI — run `cpub login` if not authed (opens browser OAuth)
terminus auth:whoami # Terminus — run `terminus auth:login` if not authed
gh auth status       # GitHub CLI — run `gh auth login` if not authed
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

The Next.js 16 upstream machine name is `nextjs-16` (UUID: `f9c1a10c-bd05-448f-9c0d-b73839e69e58`). If the GitHub repo already exists (from step 4), pass `--no-create-repo` and `--repository-name` to connect to it rather than creating a new one:

```bash
# GitHub repo already exists — connect to it:
terminus site:create $SITE_NAME "$SITE_NAME" nextjs-16 \
  --org=$PANTHEON_ORG \
  --vcs-provider=github \
  --vcs-org=$GITHUB_ORG \
  --repository-name=$SITE_NAME \
  --no-create-repo

# Or let Terminus create the GitHub repo (omit --no-create-repo and --repository-name):
terminus site:create $SITE_NAME "$SITE_NAME" nextjs-16 \
  --org=$PANTHEON_ORG \
  --vcs-provider=github \
  --vcs-org=$GITHUB_ORG
```

`--org` is required when using `--vcs-provider=github`. Find your org UUID with `terminus org:list`.

### 6. Set Content Publisher secrets

**Do this before triggering a build.** The build will fail with "Missing Pantheon Content Publisher site ID" if secrets are not set first.

Obtain `PCC_SITE_ID` and `PCC_TOKEN` from [content.pantheon.io](https://content.pantheon.io), then:

```bash
terminus secret:site:set $SITE_NAME PCC_SITE_ID "your-collection-id" --type=env --scope=web
terminus secret:site:set $SITE_NAME PCC_TOKEN "your-token" --type=env --scope=web
```

`--type=env --scope=web` is required. `env` makes them available as real `process.env.*` variables (not just readable via `pantheonGetSecret()`). `web` makes them available during both builds and runtime. Using `--scope=ic` (Integrated Composer) or `--type=runtime` will not work — the build will still fail.

Note: secrets cannot have their type or scope changed after creation. Delete and recreate if you set them incorrectly:

```bash
terminus secret:site:delete $SITE_NAME PCC_SITE_ID --yes
terminus secret:site:delete $SITE_NAME PCC_TOKEN --yes
```

**Do not use `--rebuild`** with `secret:site:set` — it triggers a PHP fatal error in the current Terminus version. Trigger rebuilds manually with an empty git commit (see step 7).

### 7. Trigger and verify the build

The Pantheon site only builds when a commit is pushed to the connected GitHub repo. If the repo was pushed before the Pantheon site was created, push a new commit to trigger the first build:

```bash
git commit --allow-empty -m "chore: trigger initial Pantheon build"
git push
```

Then watch the build:

```bash
terminus node:builds:wait $SITE_NAME.dev
```

The dev environment will be live at `https://dev-$SITE_NAME.pantheonsite.io` once the build succeeds.

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

On Pantheon, these are set as secrets available at both build and runtime:

```bash
terminus secret:site:set $SITE_NAME PCC_SITE_ID "..." --type=env --scope=web
terminus secret:site:set $SITE_NAME PCC_TOKEN "..."   --type=env --scope=web
```

See step 6 in the scaffold workflow for details on why `--type=env --scope=web` is required.

## Architecture

**Routing:** Next.js App Router (`app/` directory).

**Content fetching:** `@pantheon-systems/cpub-react-sdk` handles all Content Publisher API calls. Content comes from Google Docs via the PCC add-on; `PCC_SITE_ID` and `PCC_TOKEN` identify which collection to pull from.

**Cache handler:** `cacheHandler.mjs` / `useCacheHandler.mjs` — file-based locally, GCS-backed on Pantheon. Configured in `next.config.js`. Don't modify the cache handler without understanding Pantheon's caching layer.

**Styling:** Tailwind CSS with `@tailwindcss/typography`. Config in `tailwind.config.cjs`.

**Testing:** Vitest for unit/snapshot tests (`__tests__/`), Playwright for E2E (`playwright-tests/`). Snapshot tests use `@testing-library/react`. Update snapshots when making presentational changes.

## Pantheon deployment

The Pantheon site is connected to this GitHub repo via `--vcs-provider=github` at site creation time (see scaffold steps above). Pushing to `main` triggers a build automatically. The dev environment URL is `https://dev-{site-name}.pantheonsite.io`.

## Key references

- [Content Publisher docs](https://docs.content.pantheon.io)
- [Pantheon Next.js docs](https://docs.pantheon.io/nextjs)
- [Content Publisher tutorial](https://docs.pantheon.io/nextjs/content-publisher-tutorial)
