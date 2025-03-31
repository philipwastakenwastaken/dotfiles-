set -U fish_greeting

alias vim nvim
set -gx EDITOR nivm

alias dt "dotnet test"
alias dr "dotnet restore --interactive"

alias lg lazygit

alias ls "eza -1 --icons --group-directories-first"

starship init fish | source
