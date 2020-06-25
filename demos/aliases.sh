promptcol="$(tput sgr0)$(tput setaf 220)"
cmdcol="$(tput sgr0)$(tput bold)"
normalcol="$(tput sgr0)"
trap 'echo -n "$normalcol"' DEBUG
PS1="\n\[$promptcol\]\w\$ \[$cmdcol\]"

alias cdd="cd ${PWD}"


# Generate args to highlight changed lines for bat
BAT_LANG=""
batdf() { hArgs=$(diff --unchanged-line-format="" --old-line-format="" --new-line-format="%dn " ${1} ${2} | xargs -n1 -I {} printf -- '-H %s:%s ' {} {}); bat ${BAT_LANG} ${2} $hArgs; }
alias batd=batdf
setBatLangf() { if [[ "${1}" == "" ]]; then export BAT_LANG=""; else export BAT_LANG="-l ${1}"; fi; alias bat="bat ${BAT_LANG}"; }
alias setBatLang=setBatLangf
setBatLang ""
# Usage example:
# setBatLang Dockerfile
# bat Dockerfile
# batd Dockerfile Dockerfile2
# setBatLang exclude
# bat .dockerignore
# batd .dockerignore .dockerignore2
# To use default language detection, set to empty string:
# setBatLang

#brew install colordiff
# catd - like diff, but side-by-side and colored
catdf() { colordiff -yW"`tput cols`" ${1} ${2}; }
alias catd=catdf