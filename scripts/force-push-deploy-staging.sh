#!/bin/sh
#Used to force push the current git branch to deploy/staging.
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
git push origin $CURRENT_BRANCH:deploy/staging --force