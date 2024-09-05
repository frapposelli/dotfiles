function sysupdate
  if command -s toilet > /dev/null; toilet -f pagga "sysupdate"; end
  if command -s git > /dev/null; and test -d $HOME/.dotfiles
	cd $HOME/.dotfiles
	git pull
	cd -
  end
  if command -s brew > /dev/null
	brew bundle --global -q
	brew update -q
	brew upgrade -g -q
	brew cleanup -q
  end
end

function sysupdate_and_die
  sysupdate
  if command -s toilet > /dev/null;toilet -f pagga "shutting down system"; end
  sudo shutdown -h now
end
