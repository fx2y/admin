#!/bin/bash

# Get commands from Katacoda files
#
# Hard-coded to be executed from the admin dir and to work for the scenario list below
#
# Usage examples:
#   source katacoda_get_commands.sh
#   source katacoda_get_commands.sh 0         # exclude metadata: "```" and "```{{command}}" lines

INCLUDE_METADATA=${1:-1}

KC_ROOT_DIR=../katacoda-scenarios
scenarios="1-intro-workflow
2-kustomize
3-tekton
4-argocd
5-manage-triggers
6-buildpacks
7-final-workflow"

OUTPUT_DIR=temp/katacoda_get_commands_output
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

function get_commands() {
  input_file=${1}
  output_file=${2}
  echo "[get_commands] Input file $input_file -----> Output file $output_file"

  isCommandBlock=false
  linenumber=0
  while read line; do
    ((linenumber=linenumber+1))
    # echo "[get_commands] $input_file:$linenumber"
    # Update isCommandBlock if necessary
    if [[ "$line" =~ ^\`\`\`$ ]]; then
      echo "[get_commands] $input_file:$linenumber --- command block START"
      isCommandBlock=true
      if (( ${INCLUDE_METADATA} == 1 )); then
        echo "$line" >> $output_file
      fi
      continue
    elif [[ "$line" =~ ^\`\`\`{.*  ]]; then
      echo "[get_commands] $input_file:$linenumber --- command block END"
      isCommandBlock=false
      if (( ${INCLUDE_METADATA} == 1 )); then
        echo "$line" >> $output_file
      fi
      continue
    fi

    if [[ $isCommandBlock = "true" ]]; then
      echo "$line" >> $output_file
    fi

  done <$input_file

}

# loop through scenarios
for scenario in $scenarios
do
  # loop through files in a scenario
  for file in $KC_ROOT_DIR/$scenario/step[1-9].md
  do
    mkdir -p $OUTPUT_DIR/$scenario
    commands=$OUTPUT_DIR/$scenario/$scenario.txt
    #echo -e "Input file $file -----> Output file $commands"
    touch $commands
    get_commands $file $commands
  done    # loop through files in a scenario
done    # loop through scenarios
