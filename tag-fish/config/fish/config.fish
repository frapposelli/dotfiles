set -gx GOPATH ~/Development/goworkspace

set -gx PATH ~/.bin $GOPATH/bin /usr/local/sbin $PATH

set -gx HOMEBREW_CASK_OPTS --appdir=/Applications

set -gx P4EDITOR vi

set -gx P4CONFIG .p4config

set -gx P4PORT perforce.eng.vmware.com:1666

#set -gx PATH /build/trees/bin /build/apps/bin /build/toolchain/mac32/perforce-r14.1 $PATH

set -gx RBENV_ROOT /usr/local/var/rbenv
. (rbenv init -|psub)

#if status –is-interactive
#  set PATH $HOME/.rbenv/bin $PATH
#  . (rbenv init - | psub)
#end
