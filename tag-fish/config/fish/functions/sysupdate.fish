function sysupdate
  if command -s toilet > /dev/null; toilet -f pagga "sysupdate"; end
  if command -s git > /dev/null; and test -d $HOME/.dotfiles
	if command -s toilet > /dev/null
		toilet -f wideterm "* updating dotfiles"
	end
	cd $HOME/.dotfiles
	git pull
	if command -s rcup > /dev/null
		rcup -t mac -t fish -t vim -t ssh -t tmux
	end
	cd -
  end
  if command -s brew > /dev/null
	if command -s toilet > /dev/null
		toilet -f wideterm "* updating homebrew"
	end
	brew bundle --global -q
	brew update -q
	brew upgrade -g -q
	brew cleanup -q --prune=all --scrub
  end
end

function sysupdate_and_die
  sysupdate
  if command -s toilet > /dev/null;toilet -f pagga "shutting down system"; end
  sudo shutdown -h now
end
