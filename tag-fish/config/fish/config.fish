set -gx COLORTERM truecolor
set -gx EDITOR nvim
set -gx LANG en_US.UTF-8    # Adjust this to your language!
set -gx LC_ALL en_US.UTF-8  # Adjust this to your locale!
set -gx VIRTUAL_ENV_DISABLE_PROMPT true
# set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
set -gx GOPATH $HOME/Development/goworkspace
set -x PATH ~/.bin $GOPATH/bin $PATH
set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
set -gx HOMEBREW_CASK_OPTS --appdir=/Applications
set -gx DOCKER_BUILDKIT 1
set -gx COMPOSE_DOCKER_CLI_BUILD 1
set -g fish_key_bindings fish_vi_key_bindings
set -g fish_bind_mode insert

# Title options
set -g theme_title_display_process yes
set -g theme_title_display_path yes
set -g theme_title_display_user yes
set -g theme_title_use_abbreviated_path yes

# Prompt options
set -g theme_display_ruby no
set -g theme_display_virtualenv no
set -g theme_display_vagrant no
set -g theme_display_vi no
set -g theme_display_k8s_context no
set -g theme_display_user ssh
set -g theme_display_jobs_verbose yes
set -g theme_display_hostname ssh
set -g theme_show_exit_status yes
set -g theme_git_worktree_support no
set -g theme_display_git yes
set -g theme_display_git_dirty yes
set -g theme_display_git_untracked yes
set -g theme_display_git_ahead_verbose yes
set -g theme_display_git_dirty_verbose yes
set -g theme_display_git_master_branch yes
set -g theme_display_date yes
set -g theme_display_cmd_duration yes
set -g theme_powerline_fonts yes
set -g theme_nerd_fonts yes
set -g theme_color_scheme dark
set -g theme_newline_cursor no

bind -M insert \cg forget

alias ccat="pygmentize -O style=monokai -f console256 -g"
alias k=kubectl
alias g=git
alias d=docker

if which asdf > /dev/null; status --is-interactive; and source (brew --prefix asdf)/asdf.fish; end
if which direnv > /dev/null; direnv hook fish | source; end
if which goenv > /dev/null; status --is-interactive; and source (goenv init -|psub); end
if which rbenv > /dev/null; status --is-interactive; and source (rbenv init -|psub); end
if which swiftenv > /dev/null; status --is-interactive; and source (swiftenv init -|psub); end
if which pyenv > /dev/null; status is-login; and pyenv init --path | source; end
if which op > /dev/null; status --is-interactive; and source /Users/fabio/.config/op/plugins.sh; end

switch (uname)
	case "Darwin"
		switch (uname -p)
			case "arm"
				set -x PATH /opt/homebrew/sbin /opt/homebrew/bin $PATH
			case "i386"
				set -x PATH /usr/local/sbin /usr/local/bin $PATH
		end
		set -gx PATH ~/Development/google-cloud-sdk/bin /Library/TeX/texbin $PATH
		function nvm
		   bass source (brew --prefix nvm)/nvm.sh --no-use ';' nvm $argv
		end
		set -x NVM_DIR ~/.nvm
		nvm use default --silent
	case "Linux"
end

fish_add_path /usr/local/opt/binutils/bin

