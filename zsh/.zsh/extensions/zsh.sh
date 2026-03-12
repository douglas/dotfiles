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

# ZSH Abbreviations (fish-like abbreviations that expand inline)
if [[ -f /usr/share/zsh/plugins/zsh-abbr/zsh-abbr.plugin.zsh ]]; then
	source /usr/share/zsh/plugins/zsh-abbr/zsh-abbr.plugin.zsh
elif [[ -f /opt/homebrew/share/zsh-abbr/zsh-abbr.plugin.zsh ]]; then
	source /opt/homebrew/share/zsh-abbr/zsh-abbr.plugin.zsh
fi

if (( $+commands[abbr] )) || (( $+functions[abbr] )); then
	# General
	abbr -q -S "zshconfig=zed ~/.public_dotfiles ~/.private_dotfiles"
	abbr -q -S "zshreload=source ~/.zshrc"
	abbr -q -S "lzd=lazydocker"
	abbr -q -S "lzg=lazygit"

	# Git
	abbr -q -S "g=git"
	abbr -q -S "gadd=git add"
	abbr -q -S "gadda=git add ."
	abbr -q -S "gcb=git branch --show-current"
	abbr -q -S "gci=git ci -m "
	abbr -q -S "gciw=git ci -m 'wip'"
	abbr -q -S "gcia=git cia --amend"
	abbr -q -S "gdiff=git ddiff"
	abbr -q -S "grfixup=git rfixup"
	abbr -q -S "gnfixup=git nfixup"
	abbr -q -S "gcp=git cp"
	abbr -q -S "gclean=git clean -fd"
	abbr -q -S "gcleanup=git cleanup-merged && git cleanup-gone"
	abbr -q -S "gcob=git cob"
	abbr -q -S "gco=git co"
	abbr -q -S "gnb=git checkout -b dsa/"
	abbr -q -S "grbs=git rebase --skip"
	abbr -q -S "grbc=git rebase --continue"
	abbr -q -S "grba=git rebase --abort"
	abbr -q -S "grbi=git rebase --interactive"
	abbr -q -S "grbm=git rebase origin/master"
	abbr -q -S "gpull=git pull"
	abbr -q -S "gpush=git push"
	abbr -q -S "gpushu=git pushu"
	abbr -q -S "gpushf=git pf"
	abbr -q -S "gst=git status"
	abbr -q -S "grsmr=git reset --hard origin/master"
	abbr -q -S "grsmn=git reset --hard origin/main"
	abbr -q -S "grs=git reset HEAD~"

	# Ruby on Rails
	abbr -q -S "bi=bundle install"
	abbr -q -S "bic=bundle install --conservative"
fi
