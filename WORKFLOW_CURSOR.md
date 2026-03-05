## KVent – Cursor Git Workflow Cheat Sheet

### 1. Branching

- **Start a feature**

```bash
git checkout main
git pull
git checkout -b feature/<short-name>
```

- **After finishing and testing**

```bash
git checkout main
git merge --no-ff feature/<short-name>
git branch -d feature/<short-name>
```

### 2. Working in Cursor

- **Before starting work**
  - Open the repo in Cursor.
  - Check the **Source Control** panel → make sure there are no unexpected changes.

- **While editing**
  - Edit `main.lua` and `files/*.lua` normally.
  - Use the **diff view** in Source Control to review each file before committing.

### 3. Comparing with HC3 exports

- Save HC3 exports under `test/`, e.g.:
  - `test/main_HC3.lua`
  - `test/hc.lua`

- Compare in Cursor:
  - Open both files → right‑click tab → **Compare with Selected**.

- Or compare in the terminal inside Cursor:

```bash
git diff --no-index test/hc.lua files/KomfoBinarySwitch.lua
git diff --no-index test/main_HC3.lua main.lua
```

### 4. Commit cycle

1. Make and save changes.
2. In Source Control:
   - Stage the relevant files.
   - Write a clear message, e.g. `Add service 1007 notifications`.
   - Commit.

Or from the terminal:

```bash
git status
git diff           # optional: review
git commit -am "Add service 1007 notifications"
```

### 5. Tag stable versions

After a version is tested on HC3:

```bash
git checkout main
git tag -a vX.Y.Z -m "Short description"
git push --follow-tags   # if you push to GitHub
```

Examples:

```bash
git tag -a v1.0.0 -m "Initial stable HC3 version"
git tag -a v1.1.0 -m "Service 1007 notifications"
```

### 6. Safety before big changes / restores

- Create a backup branch in Cursor’s terminal:

```bash
git checkout -b backup/$(date +%Y-%m-%d)-pre-change
```

- Now it’s safe to:
  - Run `git restore` on files.
  - Experiment heavily on `feature/*` branches.

You can always compare to the backup branch later:

```bash
git diff backup/2026-02-26-pre-change..main
```

