#!/bin/bash
# SOURCE WITHIN <mamba>/bin/activate
msg=(
  user=$USER
  pyenv=$(which python | awk -F'/' 'NR==1 { print $(NF-2) }')
  pypath="$(which python | sed 's/ /\\ /g')"
  host=$(hostname --long)
  time=$(date +%s)
  mamba="$(which mamba | sed 's/ /\\ /g')"
)
logger -t PythonEnvUsageTracking "${msg[@]}"
unset msg
