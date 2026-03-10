##
## Git functions
##

# Rebase current branch on top of a target branch
function grbmm() {
  if [ -z "$1" ]; then
    echo "Usage: grbmm <branch>"
  else
    git branch --show-current | xargs git merge-base $1 | xargs git rebase -i
  fi
}

# Reset the last N commits (soft reset)
function grsh() {
  if [ -z "$1" ]; then
    echo "Usage: grsh <num_of_commits>"
  else
    git reset HEAD~$1
  fi
}

# Reset the current branch to its remote tracking branch
function grscb() {
	git reset --hard origin/$(git branch --show-current)
}

# Create a new GH PR and open in browser
function pr() { gh pr create -w }

# Delete the current branch on the remote
function grmbr() {
	git push origin -d $(git branch --show-current)
}

# Squash all commits on the current branch into one, keeping the last commit message
function gioc() {
  local last_commit_message=$(git show -s --format=%s)
  git branch --show-current | xargs git merge-base master | xargs git reset --soft
  git add -A
  git commit -m "$last_commit_message"
  git commit --amend
}
