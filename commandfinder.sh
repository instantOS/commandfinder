#!/usr/bin/env bash


echo 'generating package cache'

pkgfile -l -r '.*' | sed 's/\t/ /g' | grep -E '(/usr/bin/|/usr/local/bin/| /bin/|/usr/lib/jvm/default/bin/)..' | sort -u | sed 's~/usr/bin/~~g' | sed 's/  */ /g' > packages.txt

REPOS="$(grep -o '^[^/]*' packages.txt | sort -u)"

while read -r repo
do
    echo "processing $repo"
    grep "^$repo/" packages.txt | sed "s/^$repo\///g" | sort -u > "$repo".txt
done <<< "$REPOS"
