#
## ZSH Configuration
#

# ZSH Autosuggestions (ghost-text from history)
if [[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
	source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
	source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ZSH_HISTORY
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
setopt NO_NOMATCH                # Pass unmatched globs as literals (e.g. rake task[arg]).
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# Home/End key bindings
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ZSH Completion tweaks
zstyle ':completion:*' menu select

# Accept autosuggestion with Tab (in addition to right arrow)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(complete-word)

# Shell shortcuts

# General
alias zshconfig='zed ~/.public_dotfiles ~/.private_dotfiles'
alias zshreload='source ~/.zshrc'
alias lzd='lazydocker'
alias lzg='lazygit'

# Git
alias g='git'
alias gadd='git add'
alias gadda='git add .'
alias gcb='git branch --show-current'
alias gciw="git ci -m 'wip'"
alias gcia='git cia --amend'
alias gdiff='git ddiff'
alias grfixup='git rfixup'
alias gnfixup='git nfixup'
alias gcp='git cp'
alias gclean='git clean -fd'
alias gcleanup='git cleanup-merged && git cleanup-gone'
alias gcob='git cob'
alias gco='git co'
alias grbs='git rebase --skip'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias grbi='git rebase --interactive'
alias grbm='git rebase origin/master'
alias gpull='git pull'
alias gpush='git push'
alias gpushu='git pushu'
alias gpushf='git pf'
alias gst='git status'
alias grsmr='git reset --hard origin/master'
alias grsmn='git reset --hard origin/main'

# Ruby on Rails
alias bi='bundle install'
alias bic='bundle install --conservative'

# Worktrees
alias wr='wt-zig'

function gci() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: gci <commit message>"
		return 1
	fi

	git ci -m "$*"
}

function gnb() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: gnb <branch-suffix>"
		return 1
	fi

	git checkout -b "dsa/$1"
}

function grs() {
	local commit_count="${1:-1}"
	git reset "HEAD~${commit_count}"
}
