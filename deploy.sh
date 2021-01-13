#!/bin/sh

# If a command fails then the deploy stops
set -e

# Build the project.
printf "\033[0;32mBuilding sites...\033[0m\n"
hugo # if using a theme, replace with `hugo -t <YOURTHEME>`

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos.
printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"
git push origin main

printf "\033[0;32mDeployed.\033[0m\n"
