#
## Networking
#

# Ports in use
function piu() {
	sudo lsof -iTCP -sTCP:LISTEN -n -P
}

# Processes using a specific port
function pusp() {
  sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
}
