#
## Networking
#

# Ports in use
function openports() {
	sudo lsof -iTCP -sTCP:LISTEN -n -P
}

# Processes using a specific port
function pup() {
  sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
}
