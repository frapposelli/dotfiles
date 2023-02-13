function fish_greeting
  if which fortune > /dev/null; and which cowsay > /dev/null; fortune | cowsay -T U -e oO; end
end
