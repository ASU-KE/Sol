# .bashrc

# Source global definitions
if [[ -f /etc/bashrc ]]; then
  builtin source /etc/bashrc
fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# For forward search with readline -- Stops terminal from stopping
# when C-s is pressed.
[[ $- == *i* ]] && stty -ixon || :

# Set shell prompt
if [[ -f $HOME/.bash_prompt ]]; then
  builtin source $HOME/.bash_prompt
fi

HISTTIMEFORMAT="%F|%T "
export EDITOR=vim

# User specific aliases and functions
alias ls="/bin/ls -F --color=auto"
alias ll="/bin/ls -lF --color=auto"

