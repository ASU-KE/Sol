# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  builtin source ~/.bashrc
fi

# User specific environment and startup programs

export PATH="$PATH:$HOME/.local/bin:$HOME/bin"
