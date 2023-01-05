#!/bin/bash

# This script generates a report in csv format which shows the total commits for each user per repo
# Requires the GitHub CLI: https://github.com/cli/cli

# If $1 is passed use as org
if [ -z "$1" ]
  then
    org=$org
  else
    org=$1
fi

# Get a list of org members and repos. Save to files.
gh api --paginate /orgs/${org}/members | jq '.[].login' > tmp/members.txt
sleep 3
gh api --paginate /orgs/${org}/repos | jq -r '.[].name' > tmp/repos.txt

# Write the headers to the CSV file
echo "member,org,repo,total commits" >> results.csv

# Read the repos from the org-repos.txt file
while read -r repo; do
  # Read the members from the org-members.txt file
  while read -r member; do
    # Make a GET request to the GitHub API to get the list of commits by the member
    commits=$(gh api --paginate /repos/$org/$repo/commits | jq ".[].author.login | select(. == $member)")
    # Print the result
    if [ -z "$commits" ]; then
        echo "$member,$org,$repo,0" >> results.csv
    else
    num_commits=$(echo "$commits" | wc -l)
        echo "$member,$org,$repo,$num_commits" >> results.csv
    fi
    # sleep to prevent rate limiting
    sleep 1
  done < tmp/org-members.txt
done < tmp/org-repos.txt

# Remove the temporary files
rm tmp/members.txt
rm tmp/repos.txt

echo "Done!"
