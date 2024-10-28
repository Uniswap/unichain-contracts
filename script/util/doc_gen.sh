#!/bin/bash
set -e
forge build
rm -rf docs/autogen
# generate docs
forge doc -b -o docs/autogen

# Unstage all docs where only the commit hash changed
# Get a list of all unstaged files in the directory
files=$(git diff --name-only -- 'docs/autogen/*')

# Loop over each file
for file in $files; do
    # Check if the file exists
    if [[ -f $file ]]; then
        # Get the diff for the file, only lines that start with - or +
        diff=$(git diff $file | grep '^[+-][^+-]')
        # Check if there are any other changes in the diff besides the commit hash
        if [[ $(echo "$diff" | wc -l) -eq 2 ]]; then
            # If there are no other changes, discard the changes for the file
            git reset HEAD $file
            git checkout -- $file
        fi
    else
        echo "File $file does not exist, skipping..."
    fi
done