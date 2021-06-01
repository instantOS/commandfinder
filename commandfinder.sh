#!/usr/bin/env bash
# lightweight command-not-found handler for Arch Linux

if [ -z "$1" ]; then
    exit
fi

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
        sudo pkgfile --update || exit 1
    fi
}

echo -e "$(grep -o '[^/]*$' <<< "$SHELL"): command $1 not found\n"

if ! [ -e ~/.cache/commandfinder/confirm.txt ]; then
    echo 'inititlizing package cache'
    mkdir -p ~/.cache/commandfinder/
    cd ~/.cache/commandfinder || exit 1
    export USEDEFAULTCACHE="true"
    preparecache
    gencache &
fi

if [ -n "$USEDEFAULTCACHE" ]; then
    if ! [ -e /usr/share/commandfinder/cache ]; then
        echo 'commandfinder cache not found'
        exit 1
    fi
    cd /usr/share/commandfinder/cache || exit 1
else
    cd ~/.cache/commandfinder || exit 1
fi

FOUNDPACKAGES="$(rg "$1 " . | sed 's/^[^ ]* //g' | sort -u | sed 's/^/    sudo pacman -S /g')"
[ -z "$FOUNDPACKAGES" ] && exit

if [ "$(wc -l <<<"$FOUNDPACKAGES")" -gt 1 ]; then
    echo -e "\e[34m\e[1mIt can be installed by using one of the following commands\e[0m"
else
    echo -e "\e[34m\e[1mIt can be installed by using the following command\e[0m"
fi

echo -e "$FOUNDPACKAGES\n"
