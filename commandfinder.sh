#!/usr/bin/env bash
# lightweight command-not-found handler for Arch Linux

set -e

CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}/commandfinder"

[ -d "$CACHEDIR" ] || mkdir -p "$CACHEDIR"

gencache() {
    echo 'generating package cache'
    pkgfile -l -r '.*' | sed 's/\t/ /g' | grep -E '(/usr/bin/|/usr/local/bin/| /bin/|/usr/lib/jvm/default/bin/)..' | sort -u | sed 's~/usr/bin/~~g' | sed 's/  */ /g' >packages.txt
    REPOS="$(grep -o '^[^/]*' packages.txt | sort -u)"

    while read -r repo; do
        echo "processing $repo"
        grep "^$repo/" packages.txt | sed "s/^$repo\///g" | sort -u >"$repo"
    done <<<"$REPOS"

    echo 'finished generating cache'
    rm packages.txt
    touch confirm.txt
}

preparecache() {
    if pkgfile vim 2>&1 | grep -q 'No repo files found'; then
        sudo systemctl enable pkgfile-update.timer
        sudo pkgfile --update
    fi
}

usage() {
    echo 'usage: commandfinder commandname'
}

case "$1" in
-h|--help)
    usage
    exit
    ;;
cache)
    mkdir "${2:-commandfindercache}"
    cd "${2:-commandfindercache}"
    preparecache
    gencache
    exit
    ;;
'')
    echo 'commandfinder: requires an argument' >&2
    usage >&2
    exit 1
esac

echo -e "$(grep -o '[^/]*$' <<<"$SHELL"): command $1 not found\n"

if ! [ -e ~/.cache/commandfinder/confirm.txt ]; then
    echo 'inititlizing package cache'
    cd "$CACHEDIR"
    export USEDEFAULTCACHE="true"
    preparecache
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

if [ -n "$USEDEFAULTCACHE" ]; then
    if ! [ -e /usr/share/commandfinder/cache ]; then
        echo 'commandfinder cache not found'
        exit 1
    fi

    mkdir -p ~/.cache/commandfinderdefault

    # only link caches for installed repos
    while read -r repo; do
        if [ -e /usr/share/commandfinder/cache/"$repo" ]; then
            if ! [ -e ~/.cache/commandfinderdefault/"$repo" ]; then
                ln -s /usr/share/commandfinder/cache/"$repo" ~/.cache/commandfinderdefault/
            fi
        fi
    done <<<"$(cat /etc/pacman.conf | grep '^\[.*\]' | grep -v options | grep -o '[^][]*')"

    cd ~/.cache/commandfinderdefault

else
    cd ~/.cache/commandfinder
fi

if command -v yay &> /dev/null
then
    INSTALLCOMMAND="yay -S"
else
    INSTALLCOMMAND="sudo pacman -S"
fi

FOUNDPACKAGES="$(rg " $1$" . | sed 's/ [^ ]*$//g' | sed 's/^.*://g' | sort -u | sed "s/^/    $INSTALLCOMMAND /g")"

[ -z "$FOUNDPACKAGES" ] && exit

if [ "$(wc -l <<<"$FOUNDPACKAGES")" -gt 1 ]; then
    echo -e "\e[34m\e[1mIt can be installed by using one of the following commands\e[0m"
else
    echo -e "\e[34m\e[1mIt can be installed by using the following command\e[0m"
fi

echo ""

echo -e "\u001b[33m$FOUNDPACKAGES\n"
