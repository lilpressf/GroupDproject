🚧 Group D GitHub Guide — Branch per Task System

We are now using a branch-per-task system.
This means you will create a new branch for each feature, bug fix, or task you work on — instead of having a permanent personal branch.

This keeps the repo organized, makes code reviews easier, and prevents conflicts.

🧩 Branch setup

main → final, stable version (no one commits directly)

dev (or test) → shared integration branch

feature/your-name/task → short-term branches for each piece of work

Example branches:

feature/daan/login-page
feature/anouar/navbar-fix
feature/pieter/api-auth


After your task is merged, that branch is deleted.

🧭 Starting a new task

Make sure you’re up to date:

git checkout dev
git pull origin dev


Create a new branch for your task:

git checkout -b feature/your-name/task-name


Example:

git checkout -b feature/daan/login-form


This creates a branch off the latest dev code.

💻 Working on your task

Work normally and commit your changes often:

git add .
git commit -m "Implement login form layout"


Push your branch to GitHub:

git push -u origin feature/your-name/task-name

🔄 Keeping your branch up to date

If someone else’s work was merged into dev while you were coding, update your branch:

git fetch origin
git rebase origin/dev


If conflicts appear, fix them manually, then continue:

git add .
git rebase --continue


💡 This keeps your branch clean and based on the latest code.

🚀 Merging your task into dev

When your task is finished and tested:

Go to the Pull Requests page:
👉 https://github.com/lilpressf/GroupDproject/pulls

Click “New Pull Request”

Base branch: dev
Compare branch: your feature branch (e.g. feature/daan/login-form)

Add a clear title and description of your changes

Request a review from another team member

Once approved and tests pass → merge into dev

⚠️ Important merge rules

Only one PR to dev at a time

Always check that no other pull requests are open before merging

After a merge, everyone must update their local dev branch:

git checkout dev
git pull origin dev

🧹 After merging

Once your branch is merged:

Delete it in GitHub (tick “Delete branch” after merging).

Delete it locally:

git branch -d feature/your-name/task-name


Pull the latest dev branch:

git checkout dev
git pull origin dev


Start your next task:

git checkout -b feature/your-name/new-task

✅ Quick Summary
Task	Command
Create new branch	git checkout -b feature/name/task dev
Commit changes	git add . && git commit -m "message"
Push to GitHub	git push -u origin feature/name/task
Update branch	git fetch origin && git rebase origin/dev
Create PR	feature → dev
Update local dev	git checkout dev && git pull origin dev
Delete old branch	git branch -d feature/name/task
