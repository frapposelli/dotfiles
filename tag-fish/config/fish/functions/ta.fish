# tat: tmux attach
function tat 
  set -l name (basename `pwd` | sed -e 's/\.//g')

  if tmux ls 2>&1 | grep "$name"
    tmux attach -t "$name"
  elif [ -f .envrc ]
    direnv exec / tmux new-session -s "$name"
  else
    tmux new-session -s "$name"
  end
end
