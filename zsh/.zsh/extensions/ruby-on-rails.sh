#
## Ruby on Rails
#

# Enable YJIT
export RUBY_YJIT_ENABLE="1"
export RUBY_CONFIGURE_OPTS=--enable-yjit

##
## RVM
##
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
