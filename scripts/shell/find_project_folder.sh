#!/bin/bash
path=$(pwd)
found="F"
while [ $path != /  ] && [ $found != T ]; do
    tmp=$(find "$path" -maxdepth 1 -mindepth 1 -name ".project_folder")
    n_found=$(echo $tmp | wc -w)
    if [ $n_found -gt 0 ]; then
        found="T"
    else
        path="$(dirname "$path")"
    fi
done

echo "$path"
