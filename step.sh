#!/bin/bash

# Fail if any command fails
set -e

# Read all tags, separate them into an array
all_tags=$(git tag -l | wc -l)

if [ "$all_tags" = 0 ]; then
    # No tags, exit.
    echo "Repository contains no tags. Please make a tag first."
    exit 1
elif [ "$all_tags" = 1 ]; then
    echo "Fetching commits since first commit."

    # We have first tag, fetch since first commit (i.e., don't specify previous tag)
    changelog="$(git log --pretty=format:"%b")"
else
    echo "Fetching commits since last tag."

    # We have many tags, fetch since last one
    latest_tag=$(git describe --tags)
    previous_tag="$(git describe --abbrev=0 --tags "$(git rev-list --tags --skip=1 --max-count=1)")"

    # Get commit messages since previous tag
    changelog="$(git log --pretty=format:"%b" "$latest_tag"..."$previous_tag")"
fi

relnotes_raw="$(echo "$changelog" | grep "RelNote: ")"
relnotes="${relnotes_raw//"RelNote: "/ - }"

# Output collected information
echo "Committer: $(git log --pretty=format:"%ce" HEAD^..HEAD)"
echo "Latest tag: $latest_tag"
echo "Previous tag: $previous_tag"
echo "RelNotes:"
echo "$relnotes"

# Set environment variable for bitrise
envman add --key COMMIT_RELNOTES --value "$relnotes"

exit 0
