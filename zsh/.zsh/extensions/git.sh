##
## Git
##

## Path changes
export PATH="/Users/douglas/src/git-fuzzy/bin:$PATH"

## Aliases
alias g="git"
alias gadd="git add"
alias gbc="git branch --show-current | pbcopy"
alias gcb="git branch --show-current"
alias gclean="git clean -fd"
alias gst="git status"
alias gdiff="git diff"
alias gst="git st"
alias gci="git ci -m "
alias gcia="git cia --amend"
alias grfixup="git rfixup"
alias gnfixup="git nfixup"
alias gpf="git pf"
alias gcob="git cob"
alias gco="git co"
alias gcp="git cp"
alias gpull="git pull"
alias gpush="git push"

# Requires GitHub CLI (gh)
function pr() { gh pr create -w }

# Reset the current branch to the remote branch
function grcb() {
	git reset --hard origin/$(gcb)
}

# Delete the current branch on the remote
function gdrb() {
	git push origin -d $(gcb)
}

# Rebase the current branch on top of master
function girb() {
  if [ -z "$1" ]; then
    echo "Usage: girb <branch>"
  else
    git branch --show-current | xargs git merge-base $1 | xargs git rebase -i
  fi
}

# Run git pull in parallel for all repos in the current directory
# Requires GNU Parallel
alias updall="gfind . -maxdepth 8 -name '.git' -prune -type d -printf '%h\n' | parallel --eta 'echo {} && git -C {} pull'"

# Count the number of commits between current branch and the selected branch
function bcommits() {
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
