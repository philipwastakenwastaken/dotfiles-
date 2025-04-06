function rider
    command rider $argv >/dev/null 2>&1 &
    disown
end
