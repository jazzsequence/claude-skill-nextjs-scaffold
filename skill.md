# Scaffold a Content Publisher + Next.js Site on Pantheon

Use this skill to scaffold a new Next.js site from the Pantheon Content Publisher starter, push it to GitHub, and wire it to a new Pantheon site — end to end.

## Usage

```
/scaffold-cpub-nextjs <site-name> [github-org]
```

- `site-name` — machine name for the GitHub repo and Pantheon site (lowercase, hyphens only)
- `github-org` — GitHub org or username (defaults to the authenticated user's personal account)

---

## Instructions

Work through each step in order. Stop and confirm with the user before any destructive action. If a step fails, diagnose before retrying.

### Step 0 — Confirm the user has a Content Publisher collection

Before doing anything else, ask the user:

> Do you have a Content Publisher collection set up at content.pantheon.io with a Collection ID and Token ready?

If **no**: walk them through creating one:
1. Go to [content.pantheon.io](https://content.pantheon.io) and sign in
2. Navigate to **Collections** → **+ New collection**, select a Google account, set publishing permissions
3. Copy the **Collection ID** from the collection page — this is `PCC_SITE_ID`
4. Navigate to **Tokens** in the left nav → create a new token → copy it immediately — this is `PCC_TOKEN` (shown only once)

Do not proceed until the user confirms they have both values.

### Step 1 — Verify prerequisites

Check that all three CLIs are installed and authenticated:

```bash
cpub whoami
terminus auth:whoami
gh auth status
```

If any check fails:
- `cpub` not found: `npm install -g @pantheon-systems/cpub-cli`
- `cpub` not authed: `cpub login` (opens browser OAuth flow)
- `terminus` not found: install from https://github.com/pantheon-systems/terminus
- `terminus` not authed: `terminus auth:login`
- `gh` not found: `brew install gh`
- `gh` not authed: `gh auth login`

Do not proceed until all three pass.

### Step 2 — Scaffold the codebase

Run from the **parent** directory of where the project should live. If a directory named `$SITE_NAME` already exists, back it up first to avoid losing any existing files (e.g. `CLAUDE.md`, `.claude/`):

```bash
cp -r $SITE_NAME /tmp/$SITE_NAME-backup
rm -rf $SITE_NAME
```

Then scaffold:

```bash
cpub init $SITE_NAME --ts --eslint --appRouter --non-interactive
```

Restore any backed-up files into the new directory afterward.

### Step 3 — Initialize git

```bash
cd $SITE_NAME
git init
git add .
git commit -m "Initial commit: Content Publisher Next.js starter"
```

### Step 4 — Create a GitHub repo and push

If `$GITHUB_ORG` was provided:
```bash
gh repo create $GITHUB_ORG/$SITE_NAME --private --source=. --remote=origin --push
```

If no org was provided (personal account):
```bash
gh repo create $SITE_NAME --private --source=. --remote=origin --push
```

Confirm it succeeded:
```bash
gh repo view $SITE_NAME --json url -q .url
```

### Step 5 — Select a Pantheon org

Run:
```bash
terminus org:list
```

Show the output to the user and ask which org the site should be created under. Wait for their selection before continuing.

### Step 6 — Create the Pantheon site

Using the upstream machine name `nextjs-16` (UUID: `f9c1a10c-bd05-448f-9c0d-b73839e69e58`) and the org UUID selected in step 5:

```bash
terminus site:create $SITE_NAME "$SITE_NAME" nextjs-16 \
  --org=$PANTHEON_ORG \
  --vcs-provider=github \
  --vcs-org=$GITHUB_ORG \
  --repository-name=$SITE_NAME \
  --no-create-repo
```

### Step 7 — Set Content Publisher secrets

**Set secrets before triggering a build** — the build will fail without them.

Ask the user for their `PCC_SITE_ID` and `PCC_TOKEN` if not already collected in step 0, then:

```bash
terminus secret:site:set $SITE_NAME PCC_SITE_ID "$PCC_SITE_ID" --type=env --scope=web
terminus secret:site:set $SITE_NAME PCC_TOKEN "$PCC_TOKEN" --type=env --scope=web
```

`--type=env --scope=web` is required — any other combination will not make the values available as `process.env.*` during the build.

If you need to correct a secret (type/scope cannot be changed after creation):
```bash
terminus secret:site:delete $SITE_NAME PCC_SITE_ID --yes
terminus secret:site:delete $SITE_NAME PCC_TOKEN --yes
# then re-run the set commands above
```

Do not use `--rebuild` with `secret:site:set` — it triggers a PHP fatal error in the current Terminus version.

### Step 8 — Trigger and verify the build

Since the GitHub repo was pushed before the Pantheon site existed, trigger the first build with an empty commit:

```bash
git commit --allow-empty -m "chore: trigger initial Pantheon build"
git push
```

Watch the build:
```bash
terminus node:builds:wait $SITE_NAME.dev
```

Once `BUILD_SUCCESS` is confirmed, the dev environment is live at:
```
https://dev-$SITE_NAME.pantheonsite.io
```

---

## What you end up with

- A Next.js 16 + TypeScript codebase from the official Content Publisher starter
- A private GitHub repo connected to a Pantheon Next.js site via the Pantheon GitHub App
- `PCC_SITE_ID` and `PCC_TOKEN` set as Pantheon secrets, available at build and runtime
- A live dev environment ready to receive content from Google Docs via the Content Publisher add-on

---

## Key references

- [Content Publisher docs](https://docs.content.pantheon.io)
- [Pantheon Next.js docs](https://docs.pantheon.io/nextjs)
- [Content Publisher tutorial](https://docs.pantheon.io/nextjs/content-publisher-tutorial)
