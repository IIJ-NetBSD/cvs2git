#!/bin/sh


git show --format='%ai' | head -1 > /tmp/git.$$
git add -A && env GIT_AUTHOR_DATE="`cat /tmp/git.$$`" GIT_COMMITTER_DATE="`cat /tmp/git.$$`" GIT_AUTHOR_NAME='from cvs to git' GIT_AUTHOR_EMAIL='from cvs to git' GIT_COMMITTER_NAME='from cvs to git' GIT_COMMITTER_EMAIL='from cvs to git' git commit -m 'sync from cvs repository'
