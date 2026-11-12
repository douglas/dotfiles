##
## macOS configurations
##

##
## Homebrew
##
export HOMEBREW_NO_ANALYTICS=1
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

##
## Rust
##
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

##
## Bundler
##
# mysql2 builds against Homebrew's mysql@8.0 here. An env var, not the shared
# ~/.bundle/config, so Linux machines keep their system mysql_config.
[[ -x /opt/homebrew/opt/mysql@8.0/bin/mysql_config ]] &&
	export BUNDLE_BUILD__MYSQL2="--with-mysql-config=/opt/homebrew/opt/mysql@8.0/bin/mysql_config"

##
## RubyMine
##
alias cd-rubymine-gems='cd $HOME/Applications/RubyMine.app/Contents/plugins/ruby/rb/gems'

##
## VS Code
##
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
