##
## Git
##

## Git Aliases
alias g="git"

### Add
alias gadd="git add"
alias gadda='git add .'

# Branches
alias gbc="git branch --show-current | pbcopy"
alias gcb="git branch --show-current"

### Commit
alias gci="git ci -m "
alias gciw="git ci -m 'wip'"
alias gaciw="gadda & gciw"
alias gcia="git cia --amend"

### Diff
alias gdiff="git ddiff"

### Fixup
alias grfixup="git rfixup"
alias gnfixup="git nfixup"

### Cherry Pick
alias gcp="git cp"

### Cleanup
alias gclean="git clean -fd"
alias gcleanup="git cleanup-merged && git cleanup-gone"

### Checkout / New Branch
alias gcob="git cob"
alias gco="git co"
alias gnb="git checkout -b dsa/$1"

### Rebase
alias grbs="git rebase --skip"
alias grbc="git rebase --continue"
alias grba="git rebase --abort"
alias grbi="git rebase --interactive"
alias grbm="git rebase origin/master"

# Rebase the current branch on top of master
function grbmm() {
  if [ -z "$1" ]; then
    echo "Usage: girb <branch>"
  else
    git branch --show-current | xargs git merge-base $1 | xargs git rebase -i
  fi
}

# Pull
alias gpull="git pull"
alias gpush="git push"
alias gpushu="git pushu"
alias gpushf="git pf"

# Status
alias gst="git status"

# Git Reset
alias grsmr="git reset --hard origin/master"
alias grsmn="git reset --hard origin/main"
alias grs="git reset HEAD~"

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

# Run git pull in parallel for all repos in the current directory
# Requires GNU Parallel
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
