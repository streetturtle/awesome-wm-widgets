#!/usr/bin/env bash

HOST='https://api.bitbucket.org'
ACCOUNT_ID=''
WORKSPACE=''
REPO_SLUG=''

curl -s -n "${HOST}/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests?fields=values.title,values.links.html,values.author.display_name,values.author.links.avatar&q=reviewers.account_id+%3D+%22${ACCOUNT_ID}%22"