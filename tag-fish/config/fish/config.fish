set -gx GOPATH ~/Development/goworkspace

set -gx PATH ~/.bin $GOPATH/bin $PATH

set -gx HOMEBREW_CASK_OPTS --appdir=/Applications

set -gx RBENV_ROOT /usr/local/var/rbenv
. (rbenv init -|psub)
