function fish_greeting
  if which fortune2 > /dev/null; and which cowsay > /dev/null; fortune | cowsay -T U -e oO; end
end
