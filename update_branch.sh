#!/bin/sh

CVS=/usr/local/bin/cvs
CVS_REPOSITORY_DIR=/home/cvs/cvs2git/cvsroot-netbsd
CVS_MODULE=src


WORKDIR2=work.increment
GITDIR=gitwork
CVSTMPDIR=cvstmp
TMPDIR=/var/tmp


BRANCH=$1; shift

if [ "X$BRANCH" = "X" ]; then
	echo 'usage: update_branch.sh <BRANCH>'
	exit
fi

(cd $GITDIR; git checkout ${BRANCH})

# get last commit timestamp about ${BRANCH}
git --git-dir=${GITDIR}/.git show ${BRANCH} --format='%at' 2> /dev/null | head -1 > ${WORKDIR2}/timestamp.git 
if [ ! -s ${WORKDIR2}/timestamp.git ]; then
	echo branch \"${BRANCH}\" is not exists
	exit 1
fi

# set timestamp
perl -e '$t = shift; utime $t - 1, $t - 1, shift' `cat ${WORKDIR2}/timestamp.git` ${WORKDIR2}/timestamp.git

(here=`pwd`; cd ${CVS_REPOSITORY_DIR}/${CVS_MODULE} && find . -type f -newer $here/${WORKDIR2}/timestamp.git -name '*,v' -print0 | xargs -0 -n5000 $here/rcs2js) > ${WORKDIR2}/log

env TMPDIR=/var/tmp sort ${WORKDIR2}/log > ${WORKDIR2}/log.sorted

#	rm ${WORKDIR2}/log
#	(cd ${CVSTMPDIR} && ${CVS} -q update -dA)

rm -fr ${CVSTMPDIR}
${CVS} -d ${CVS_REPOSITORY_DIR} co -d ${CVSTMPDIR} ${CVS_MODULE}

./js2jslog_branch -t `cat ${WORKDIR2}/timestamp.git` -d ${WORKDIR2} ${WORKDIR2}/log.sorted

./jslog2gitappendcommit ${WORKDIR2}/commit.${BRANCH}.jslog ${BRANCH} ${GITDIR} ${CVSTMPDIR}
