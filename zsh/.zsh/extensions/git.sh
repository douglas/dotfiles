##
## Git
##

## Git abbreviations (defined in zsh.sh)
## Git aliases (complex commands that don't benefit from expansion)
alias gcleanup="git cleanup-merged && git cleanup-gone"

# Rebase the current branch on top of master
function grbmm() {
  if [ -z "$1" ]; then
    echo "Usage: girb <branch>"
  else
    git branch --show-current | xargs git merge-base $1 | xargs git rebase -i
  fi
}


function grsh() {
  if [ -z "$1" ]; then
    echo "Usage: grsh <num_of_commits>"
  else
    git reset HEAD~$1
  fi
}

# Reset the current branch to the remote branch
function grscb() {
	git reset --hard origin/$(gcb)
}

### Auxiliary Functions / Methods

# Creates a new GH PR - requires GitHub CLI (gh)
function pr() { gh pr create -w }

# Delete the current branch on the remote
function grmbr() {
	git push origin -d $(gcb)
}

# Run git pull in parallel for all repos in the current directory (kept as alias — has pipes)
alias updall="gfind . -maxdepth 8 -name '.git' -prune -type d -printf '%h\n' | parallel --eta 'echo {} && git -C {} pull'"

# Count the number of commits between current branch and the selected branch
function gbcommits() {
  if [ -z "$1" ]; then
    echo "Usage: bcommits <branch>"
  else
    git rev-list "$branch..$(gcb)"  --count
  fi
}

# Squash the last N commits between the current branch and the selected branch
function grsquash() {
  git rebase --autosquash HEAD~$(bcommits)
}

## TODO: Document

function gioc {
  local last_commit_message=`git show -s --format=%s`
  git branch --show-current | xargs git merge-base master | xargs git reset --soft
  git add -A
  git commit -m "$last_commit_message"
  git commit --amend
}
