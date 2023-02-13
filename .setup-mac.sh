#!/bin/bash
fancy_echo() {
  local fmt="$1"; shift
  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}
set -e
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# ask for sudo password
sudo -v

brew_install_or_upgrade() {
  if brew_is_installed "$1"; then
    if brew_is_upgradable "$1"; then
      fancy_echo "Upgrading %s ..." "$1"
      brew upgrade "$@"
    else
      fancy_echo "Already using the latest version of %s. Skipping ..." "$1"
    fi
  else
    fancy_echo "Installing %s ..." "$1"
    brew install "$@"
  fi
}

brew_is_installed() {
  local name="$(brew_expand_alias "$1")"

  brew list -1 | grep -Fqx "$name"
}

brew_is_upgradable() {
  local name="$(brew_expand_alias "$1")"

  ! brew outdated --quiet "$name" >/dev/null
}

brew_tap() {
  brew tap "$1" 2> /dev/null
}

brew_expand_alias() {
  brew info "$1" 2>/dev/null | head -1 | awk '{gsub(/:/, ""); print $1}'
}

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    export PATH="/usr/local/bin:$PATH"
else
  fancy_echo "Homebrew already installed. Skipping ..."
fi

fancy_echo "Updating Homebrew formulas ..."
brew update
brew_tap 'homebrew/bundle'
brew_install_or_upgrade 'fish'

case "$SHELL" in
  */fish) : ;;
  *)
    fancy_echo "Changing your shell to fish ..."
      if ! grep -q fish /etc/shells; then
        # shellcheck disable=SC2005
        echo "$(which fish)" | sudo tee -a /etc/shells
      fi
      sudo chsh -s "$(which fish)" "$USER"
    ;;
esac

if ! command -v rcup >/dev/null; then
  brew_tap 'thoughtbot/formulae'
  brew_install_or_upgrade 'rcm'
fi

fancy_echo "Setting up .dotfiles ..."
if ! test -d "$HOME/.dotfiles"; then
  git clone https://github.com/frapposelli/dotfiles.git "$HOME/.dotfiles"
else
  cd "$HOME/.dotfiles" && git pull && cd -
fi

fancy_echo "Applying RC files"
env "RCRC=$HOME/.dotfiles/rcrc" rcup -t mac -t fish -t ssh -t tmux -t vim

fancy_echo "Installing bundle"
brew bundle install --file "$HOME/.Brewfile"

if ! test -d "$HOME/.local/share/omf/"; then
  fancy_echo "Installing oh-my-fish"
  curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
  omf i bobthefish
  omf i bass
fi
