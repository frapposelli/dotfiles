set -gx GOPATH ~/Development/goworkspace
alias g=git
alias d=docker
set -gx PATH ~/.bin $GOPATH/bin $PATH
eval (direnv hook fish)