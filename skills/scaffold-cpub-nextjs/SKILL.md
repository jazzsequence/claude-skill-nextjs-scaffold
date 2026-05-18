# Scaffold a Content Publisher + Next.js Site on Pantheon

Use this skill to scaffold a new Next.js site from the Pantheon Content Publisher starter, push it to GitHub, and wire it to a new Pantheon site — end to end.

## Usage

```
/jazzsequence-skills:scaffold-cpub-nextjs <site-name> [github-org]
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

Run and **show the full output to the user** before asking them to choose:
```bash
terminus org:list
```

The user cannot see command output unless you explicitly present it to them. Display the org names and IDs, then ask which org the site should be created under. Wait for their selection before continuing.

### Step 6 — Create the Pantheon site and set secrets

Using the upstream machine name `nextjs-16` (UUID: `f9c1a10c-bd05-448f-9c0d-b73839e69e58`) and the org UUID selected in step 5.

Run site creation **in a background Bash task** (not with `&` — that gets killed when the command block ends). While it runs, poll for the site to exist and set secrets as soon as it does, so the first build has credentials available.

Run site creation as a background task, then in a separate command poll and set secrets:

```bash
# Step 1: start site creation (run as background Bash task)
terminus site:create $SITE_NAME "$SITE_NAME" nextjs-16 \
  --org=$PANTHEON_ORG \
  --vcs-provider=github \
  --vcs-org=$GITHUB_ORG \
  --repository-name=$SITE_NAME \
  --no-create-repo
```

```bash
# Step 2: poll until site exists, then set secrets immediately
until terminus site:info $SITE_NAME &>/dev/null; do sleep 3; done
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

### Step 7 — Verify the build

The site creation workflow connects the GitHub repo and triggers the first build automatically.

**Important:** `terminus node:builds:wait` will fail with "This command only works for sites using external VCS" until the site creation workflow fully completes. This is expected — do not interpret it as an error, do not attempt to delete or recreate the site. Just keep polling.

```bash
until terminus node:builds:wait $SITE_NAME.dev 2>/dev/null; do
  echo "Waiting for site provisioning to complete..."
  sleep 15
done
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

## Teardown

To fully destroy a scaffolded site, confirm with the user which of the three components to remove (Pantheon site, GitHub repo, local directory) before deleting anything — each is independently destructive and irreversible.

### Delete the Pantheon site

```bash
terminus site:delete $SITE_NAME --yes
```

### Delete the GitHub repo

```bash
gh repo delete $GITHUB_ORG/$SITE_NAME --yes
```

### Delete the local directory

```bash
rm -rf /path/to/$SITE_NAME
```

### Full teardown (all three)

Confirm with the user before running. Show them exactly what will be deleted and wait for explicit approval.

```bash
terminus site:delete $SITE_NAME --yes
gh repo delete $GITHUB_ORG/$SITE_NAME --yes
rm -rf /path/to/$SITE_NAME
```

Note: deleting the Pantheon site does not affect the GitHub repo, and vice versa. The Content Publisher collection at content.pantheon.io is not deleted — manage that separately if needed.

---

## Key references

- [Content Publisher docs](https://docs.content.pantheon.io)
- [Pantheon Next.js docs](https://docs.pantheon.io/nextjs)
- [Content Publisher tutorial](https://docs.pantheon.io/nextjs/content-publisher-tutorial)
