switch (uname)
	case "Darwin"
		set -gx RBENV_ROOT /usr/local/var/rbenv
		set -gx GOPATH ~/Development/goworkspace
		set -gx P4EDITOR vi
		set -gx P4CONFIG .p4config
		set -gx P4PORT perforce.eng.vmware.com:1666
		set -gx HOMEBREW_CASK_OPTS --appdir=/Applications
		set -gx PATH ~/Development/google-cloud-sdk/bin /Library/TeX/texbin $PATH
		set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
		alias git=hub
		alias ccat="pygmentize -O style=monokai -f console256 -g"
		alias g=git
		alias d=docker
		eval (direnv hook fish)
		. (rbenv init -|psub)
	case "Linux"
end
alias g=git
alias d=docker
set -gx PATH ~/.bin $GOPATH/bin /usr/local/sbin $PATH

