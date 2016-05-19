switch (uname)
	case "Darwin"
		set -gx RBENV_ROOT /usr/local/var/rbenv
		set -gx GOPATH ~/Development/goworkspace
		set -gx P4EDITOR vi
		set -gx P4CONFIG .p4config
		set -gx P4PORT perforce.eng.vmware.com:1666
		set -gx HOMEBREW_CASK_OPTS --appdir=/Applications
		set -gx PATH ~/Development/google-cloud-sdk/bin ~/.cargo/bin $PATH
		alias git=hub
		eval (direnv hook fish)
    function code
      set -lx VSCODE_CWD $PWD
      open -n -b "com.microsoft.VSCode" --args $argv
    end
	case "Linux"
		set -gx PATH ~/.rbenv/bin $PATH
end
set -gx PATH ~/.bin $GOPATH/bin /usr/local/sbin $PATH
. (rbenv init -|psub)

test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
