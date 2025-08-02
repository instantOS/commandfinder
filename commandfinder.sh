#!/usr/bin/env bash
# lightweight command-not-found handler for Arch Linux

set -e

CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}/commandfinder"
[ -d "$CACHEDIR" ] || mkdir -p "$CACHEDIR"

gencache() {
    echo 'generating package cache'
    pacman -Fl | grep -E '(/usr/bin/|/usr/local/bin/|/bin/|/usr/lib/jvm/default/bin/)..' > "$CACHEDIR/packages.txt"
    echo 'done' >"$CACHEDIR/confirm.txt"
}

preparecache() {
    if pacman -F vim 2>&1 | grep -q 'No repo files found'; then
        if imenu --cli -c "command not found. would you like to search for it"?; then
            sudo pacman -Fy
        else
            return 1
        fi
    fi
}

usage() {
    echo 'usage: commandfinder commandname'
}


if ! [ -e "$CACHEDIR/confirm.txt" ]; then
    echo 'inititlizing package cache'
    cd "$CACHEDIR"
    preparecache || exit
    gencache &
else
    {
        if command -v idate; then
            if idate m commandfindercache; then
                cd "$CACHEDIR"
                gencache
            fi
        fi
    } &>/dev/null &
fi

if command -v yay &>/dev/null; then
    INSTALLCOMMAND="yay -S"
else
    INSTALLCOMMAND="sudo pacman -S"
fi

search_package() {
    cd "$CACHEDIR"
    FOUNDPACKAGES="$(rg "$1$" . | sed 's/ [^ ]*$//g' | sed 's/^.*://g' | sort -u | sed "s/^/    $INSTALLCOMMAND /g")"
    if [ -z "$FOUNDPACKAGES" ]; then
        echo "$1 not found"
        return 1
    fi

    if [ "$(wc -l <<<"$FOUNDPACKAGES")" -gt 1 ]; then
        echo -e "\e[34m\e[1mIt can be installed by using one of the following commands\e[0m"
    else
        echo -e "\e[34m\e[1mIt can be installed by using the following command\e[0m"
    fi

    echo ""

    echo -e "\u001b[33m$FOUNDPACKAGES\n"
}

case "$1" in
-h | --help)
    usage
    exit
    ;;
cache)
    preparecache || exit
    gencache
    exit
    ;;
'')
    echo 'commandfinder: requires an argument' >&2
    usage >&2
    exit 1
    ;;
*)
    echo -e "$(grep -o '[^/]*$' <<<"$SHELL"): command $1 not found\n"
    search_package "$1"
    exit
    ;;
esac
