
CVS_REPOSITORY_DIR=/home/cvs/cvs2git/cvsroot-netbsd
CVS_MODULE=src

CVS=/usr/local/bin/cvs
WORKDIR1=work.import
WORKDIR2=work.increment
GITDIR=gitwork
CVSTMPDIR=cvstmp
TMPDIR=/var/tmp

RSYNC_PROXY=your.proxyserver.local:8080

usage:
	@echo "usage: make <target>"


import:
	make import0
	make import1

import0:
	make get-cvsrepository
	make makeworkdir1
	make jslog
	make branchinfo

import1:
	make cvscheckout
	make creategitimport
	make gitinit
	make gitimport
	make gitreset

force-update:
	make get-cvsrepository
	make update-sync
	make repository-analyze
	make cvsupdate
	make update-commit2
	make compare-dir

update:
	make get-cvsrepository
	make update-sametime
	make compare-dir-hack
	make repository-analyze
	make cvsupdate
	make git-checkout-master
	make update-commit2
	make compare-dir
	make push

#
#
#

update-sync:
	@if [ ! -d ${CVS_REPOSITORY_DIR} ] ; then	\
		make cvscheckout;			\
	fi
	make sync-cvs-sametime-git
	make copy-from-cvs-to-git-and-commit

update-sametime:
	@if [ ! -d ${CVS_REPOSITORY_DIR} ] ; then	\
		make cvscheckout;			\
	fi
	make sync-cvs-sametime-git

repository-analyze:
	make makeworkdir2
	git --git-dir=${GITDIR}/.git show --format='%at' | head -1 > ${WORKDIR2}/timestamp.git
	perl -e '$$t = shift; utime $$t - 1, $$t - 1, shift' `cat ${WORKDIR2}/timestamp.git` ${WORKDIR2}/timestamp.git
	(here=`pwd`; cd ${CVS_REPOSITORY_DIR}/${CVS_MODULE} && find . -type f -newer $$here/${WORKDIR2}/timestamp.git -name '*,v' -print0 | xargs -0 -n5000 $$here/rcs2js) > ${WORKDIR2}/log
#	(here=`pwd`; cd ${CVS_REPOSITORY_DIR}/${CVS_MODULE} && find . -type f -name '*,v' -print0 | xargs -0 -n5000 $$here/rcs2js) > ${WORKDIR2}/log
	env TMPDIR=/var/tmp sort ${WORKDIR2}/log > ${WORKDIR2}/log.sorted
	rm ${WORKDIR2}/log
	./js2jslog_branch -t `cat ${WORKDIR2}/timestamp.git` -d ${WORKDIR2} ${WORKDIR2}/log.sorted

update-commit2:
	./jslog2gitappendcommit ${WORKDIR2}/commit.#trunk.jslog '#trunk' ${GITDIR} ${CVSTMPDIR}

update-commit-force:
	./jslog2gitappendcommit -f ${WORKDIR2}/commit.#trunk.jslog '#trunk' ${GITDIR} ${CVSTMPDIR}

distclean:
	rm -fr ${WORKDIR1} ${WORKDIR2} ${GITDIR} ${CVSTMPDIR}

sync-cvs-sametime-git:
	echo "`git --git-dir=${GITDIR}/.git show --format='%ai' | head -1`" > GITTIME
	rm -fr ${CVSTMPDIR} && env TZ=UTC ${CVS} -d ${CVS_REPOSITORY_DIR} co -D"`git --git-dir=${GITDIR}/.git show --format='%ai' | head -1`" -d ${CVSTMPDIR} ${CVS_MODULE}

sync-cvs-sametime-git2:
	rm -fr cvstmp2 && ${CVS} -d ${CVS_REPOSITORY_DIR} co -D"`git --git-dir=${GITDIR}/.git show --format='%ai' | head -1`" -d cvstmp2 ${CVS_MODULE}

compare-dir:
	./compare_dir ${CVSTMPDIR} ${GITDIR}

compare-dir-hack:
	./compare_dir -X ${CVSTMPDIR} ${GITDIR}


git-checkout-master:
	cd ${GITDIR} && git checkout master && git clean -f

push:
	./PUSH

# detect cvs repository has renamed/modified manually
copy-from-cvs-to-git-and-commit:
	cd ${GITDIR} && git checkout master && git clean -f
	cd ${CVSTMPDIR} && rsync --stats -vOcrI --exclude=CVS --exclude=.git --delete * ../${GITDIR}/
	git --git-dir=gitwork/.git show --format='%ai' | head -1 > ${WORKDIR2}/lastcommit
	-cd ${GITDIR} && git add -A && env GIT_AUTHOR_DATE="`cat ../${WORKDIR2}/lastcommit`" GIT_COMMITTER_DATE="`cat ../${WORKDIR2}/lastcommit`" GIT_AUTHOR_NAME='from cvs to git' GIT_AUTHOR_EMAIL='from cvs to git' GIT_COMMITTER_NAME='from cvs to git' GIT_COMMITTER_EMAIL='from cvs to git' git commit -m 'sync from cvs repository'

pullup_from_cvs_to_git:
	false

get-cvsrepository:
	@if [ ! -d ${CVS_REPOSITORY_DIR} ] ; then	\
		mkdir ${CVS_REPOSITORY_DIR};		\
	fi
	env RSYNC_PROXY=${RSYNC_PROXY} ./rsync_completely.sh rsync://anoncvs.NetBSD.org/cvsroot/CVSROOT ${CVS_REPOSITORY_DIR}
	env RSYNC_PROXY=${RSYNC_PROXY} ./rsync_completely.sh rsync://anoncvs.NetBSD.org/cvsroot/src     ${CVS_REPOSITORY_DIR}

cvscheckout:
	${CVS} -q -d ${CVS_REPOSITORY_DIR} co -d${CVSTMPDIR} ${CVS_MODULE}

cvsupdate:
	rm -fr ${CVSTMPDIR} && ${CVS} -d ${CVS_REPOSITORY_DIR} co -d ${CVSTMPDIR} ${CVS_MODULE}

creategitimport:
	./jslog2fastexport ${CVS_REPOSITORY_DIR}/${CVS_MODULE} ${CVSTMPDIR} ${WORKDIR1}/commit.#trunk.jslog > ${WORKDIR1}/gitimportfile

gitreset:
	(cd ${GITDIR} && git reset --hard)

gitimport:
	(cd ${GITDIR} && git fast-import) < ${WORKDIR1}/gitimportfile

gitinit:
	mkdir ${GITDIR}
	(cd ${GITDIR} && git init)

jslog: makeworkdir1
	(here=`pwd`; cd ${CVS_REPOSITORY_DIR}/${CVS_MODULE} && find . -type f -name '*,v' -print0 | xargs -0 -n5000 $$here/rcs2js) > ${WORKDIR1}/log
	sort ${WORKDIR1}/log > ${WORKDIR1}/log.sorted
	rm ${WORKDIR1}/log
	./js2jslog_branch -d ${WORKDIR1} ${WORKDIR1}/log.sorted

branchinfo:
	WD=`pwd`
	(here=`pwd`; cd ${CVS_REPOSITORY_DIR}/${CVS_MODULE} && find . -type f -name '*,v' -print0 | xargs -0 -n5000 $$here/rcs2taginfo) > ${WORKDIR1}/branchinfo
	./branchinfo2branch ${WORKDIR1}/branchinfo > ${WORKDIR1}/branches
	./branchinfo2tag    ${WORKDIR1}/branchinfo > ${WORKDIR1}/tags

makeworkdir1:
	@if [ ! -d ${WORKDIR1} ] ; then	\
		mkdir ${WORKDIR1};	\
	fi

makeworkdir2:
	@if [ ! -d ${WORKDIR2} ] ; then	\
		mkdir ${WORKDIR2};	\
	fi
