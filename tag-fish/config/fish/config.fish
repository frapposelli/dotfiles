set -gx HOMEBREW_CASK_OPTS --appdir=/Applications

set -gx RBENV_ROOT /usr/local/var/rbenv
. (rbenv init -|psub)
