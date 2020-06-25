promptcol="$(tput sgr0)$(tput setaf 220)"
cmdcol="$(tput sgr0)$(tput bold)"
normalcol="$(tput sgr0)"
trap 'echo -n "$normalcol"' DEBUG
PS1="\n\[$promptcol\]\w\$ \[$cmdcol\]"

alias cdd="cd ${PWD}"
