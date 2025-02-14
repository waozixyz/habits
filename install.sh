#!/usr/bin/env bash

# Create ~/bin if it doesn't exist
mkdir -p ~/bin

# Remove old symlink if it exists
rm -f ~/bin/habits

# Create new symlink
cp "$(pwd)/build/habits" ~/bin/habits

echo "Installed habits to ~/bin/"
