function sysupdate
  if which toilet > /dev/null;toilet -f pagga "sysupdate"; end
  if which brew > /dev/null; brew update; end
  if which brew > /dev/null; brew upgrade -g; end
  if which brew > /dev/null; brew cleanup; end
end

function sysupdate_and_die
  sysupdate
  if which toilet > /dev/null;toilet -f pagga "shutting down system"; end
  sudo shutdown -h now
end
