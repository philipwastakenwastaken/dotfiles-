set -U fish_greeting

alias vim nvim
set -gx EDITOR nvim

alias dt "dotnet test"
alias dr "dotnet restore --interactive"

alias lg lazygit

alias ls "eza -1 --icons --group-directories-first"

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

starship init fish | source
