#!/usr/bin/env bash
# Add every open pull request in REPOS to the org project (default: jambonz project 4,
# "Open PRs — Commercial") if it isn't on it yet. Removing finished PRs is left to the
# project's own workflows ("Pull request merged", "Item closed", "Auto-archive items"),
# and its "Item added to project" workflow sets Status to Todo.
#
# env: GH_TOKEN (project write + read access to the repos), REPOS (space separated
#      owner/name), PROJECT_OWNER, PROJECT_NUMBER, DRY_RUN=1 to only report
set -euo pipefail
OWNER=${PROJECT_OWNER:-jambonz}
NUMBER=${PROJECT_NUMBER:-4}
: "${REPOS:?set REPOS to a space-separated list of owner/name}"

existing=$(gh project item-list "$NUMBER" --owner "$OWNER" --limit 2000 --format json \
  --jq '.items[] | select(.content.type == "PullRequest") | .content.url')
echo "project $OWNER/$NUMBER has $(grep -c . <<< "$existing" || true) pull requests"

added=0
for repo in $REPOS; do
  while read -r url; do
    [ -n "$url" ] || continue
    grep -qxF "$url" <<< "$existing" && continue
    if [ "${DRY_RUN:-0}" = 1 ]; then
      echo "would add $url"
    else
      gh project item-add "$NUMBER" --owner "$OWNER" --url "$url" >/dev/null
      echo "added $url"
    fi
    added=$((added + 1))
  done < <(gh pr list --repo "$repo" --state open --limit 500 --json url --jq '.[].url')
done
echo "$added pull request(s) $([ "${DRY_RUN:-0}" = 1 ] && echo 'to add' || echo added)"
