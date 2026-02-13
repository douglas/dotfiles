##
## Utils
##
case "$(uname -sr)" in
  Darwin*)
    export OPERATINGSYSTEM="macos"
    ;;
  Linux*Microsoft*)
    export OPERATINGSYSTEM="wsl"
    ;;
  Linux*)
    export OPERATINGSYSTEM="linux"
    ;;
  CYGWIN*|MINGW*|MINGW32*|MSYS*)
    export OPERATINGSYSTEM="windows"
    ;;
  *)
	  export OPERATINGSYSTEM="unknown"
	  ;;
esac
