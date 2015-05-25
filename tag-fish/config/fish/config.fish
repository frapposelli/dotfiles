set -gx P4EDITOR vi

set -gx P4CONFIG .p4config

set -gx P4PORT perforce.eng.vmware.com 1666

set -gx PATH $PATH /build/trees/bin /build/apps/bin /build/toolchain/mac32/perforce-r14.1

set -gx GOPATH ~/Development/goworkspace

set -gx PATH ~/.bin $GOPATH/bin $PATH

set -gx HOMEBREW_CASK_OPTS --appdir=/Applications

set -gx RBENV_ROOT /usr/local/var/rbenv
. (rbenv init -|psub)
