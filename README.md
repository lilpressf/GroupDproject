# 🧩 Branch-Per-Task Workflow Guide

We are now using a **branch-per-task system**.

Create a **new branch for each feature, bug fix, or task**, instead of having a personal branch.  
This keeps the repo organized, makes code reviews easier, and prevents conflicts.

---

## 🏗️ Branch Setup

| Branch | Purpose |
|--------|---------|
| **main** | Final, stable version (no one commits directly) |
| **dev** | Shared integration branch |
| **feature/<your-name>/<task>** | Short-term branches for each piece of work |

### Examples
```
feature/daan/login-page
feature/anouar/navbar-fix
feature/pieter/api-auth
```

After your task is merged, that branch is deleted.

---

## 🚀 Starting a New Task

1. **Make sure you’re up to date:**
   ```bash
   git checkout dev
   git pull origin dev
   ```

2. **Create a new branch for your task:**
   ```bash
   git checkout -b feature/<your-name>/<task-name>
   ```

   **Example:**
   ```bash
   git checkout -b feature/daan/login-form
   ```

   > This creates a branch off the latest `dev` code.

---

## 🧑‍💻 Working on Your Task

Work normally and commit changes often.

```bash
git add .
git commit -m "Implement login form layout"
```

Push your branch to GitHub:

```bash
git push -u origin feature/<your-name>/<task-name>
```

---

## 🔄 Keeping Your Branch Up to Date

If other work was merged into `dev` while you were coding, rebase your branch:

```bash
git fetch origin
git rebase origin/dev
```

If conflicts appear, fix them manually, then continue:

```bash
git add .
git rebase --continue
```

> This keeps your branch clean and based on the latest code.

---

## 🔀 Merging Your Task into `dev`

When your task is finished and tested:

1. Go to **Pull Requests**:  
   https://github.com/lilpressf/GroupDproject/pulls

2. Click **"New Pull Request"**

3. Set:
   - **Base branch:** `dev`
   - **Compare branch:** your feature branch (e.g. `feature/daan/login-form`)

4. Add a clear title and description of your changes.

5. Request review from another team member.

6. Once approved and tests pass → **merge into `dev`**

---

## ⚠️ Important Merge Rules

- Only **one PR to `dev`** at a time.  
- Always check that **no other open PRs** exist before merging.  
- After a merge, **everyone must update their local `dev` branch:**
  ```bash
  git checkout dev
  git pull origin dev
  ```

---

## 🧹 After Merging

Once your branch is merged:

Delete it on GitHub (tick “Delete branch” after merging).

Delete it locally:

```bash
git branch -d feature/<your-name>/<task-name>
```

Then pull the latest `dev` and start your next branch.

---

## ✅ Quick Summary

| Task | Command |
|------|---------|
| **Create new branch** | `git checkout -b feature/<name>/<task> dev` |
| **Commit changes** | `git add . && git commit -m "message"` |
| **Push to GitHub** | `git push -u origin feature/<name>/<task>` |
| **Update branch** | `git fetch origin && git rebase origin/dev` |
| **Create PR** | `feature → dev` |
| **Update local dev** | `git checkout dev && git pull origin dev` |
| **Delete old branch** | `git branch -d feature/<name>/<task>` |

---

📘 **Summary:** Use a short-lived `feature/<your-name>/<task>` branch for each task, rebase with `dev` frequently, and merge only after review. Keep the repo clean and synchronized!
