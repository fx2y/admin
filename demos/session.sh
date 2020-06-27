#source creds.sh

RESET_FONT="\033[0m"
BOLD="\033[1m"
YELLOW="\033[38;5;11m"
BLUE="\033[0;34m"
RED="\033[0;31m"
WHITE="\033[38;5;15m"

if [[ "${ADMIN}" == "" ]]; then
  echo -e "${BOLD}${RED}ADMIN environment variable not set${RESET_FONT}"
else

  source ${ADMIN}/demos/aliases.sh

  mkdir -p ~/workspace-demo
  cd ~/workspace-demo

  echo -e "${YELLOW}###### Get demorunner and set in PATH"
  if [ ! -d demorunner ]; then
    git clone git@github.com:mgbrodi/demorunner.git
  fi
  PATH=~/workspace-demo/demorunner:$PATH
  export DEMO_DELAY=0

  echo -e "${YELLOW}###### Get the demo-files and set DEMO workspace"
  if [ ! -d demo-files ]; then
    git clone git@github.com:springone-tour-2020-cicd/demo-files.git
  fi
  export DEMO=~/workspace-demo/demo-files

fi
