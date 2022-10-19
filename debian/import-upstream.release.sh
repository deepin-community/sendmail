#!/bin/sh
set -e

VERBOSE=1

test -n "$1"

TARBALL=$1
VERSION=$(basename "$TARBALL" .tar.gz)
VERSION=${VERSION#sendmail.}
BRANCH=sendmail
SIGBRANCH=upstream-signatures
TAG=sendmail/$VERSION

if [ "$(git tag -l $TAG)" != "$TAG" ]; then

	if [ ! -f $TARBALL ]; then
		echo "Cannot find sources for $VERSION"
		exit 1
	fi

	for SIG in $TARBALL.sig ${TARBALL%.gz}.sig
	do
		if [ -f $SIG ]; then
			break
		fi
	done

	if [ ! -f $SIG ]; then
		echo "Cannot find signature for $VERSION"
		exit 1
	fi

	STAMP=$TARBALL
	if [ -f $TARBALL.stamp ]; then
		STAMP=$TARBALL.stamp
	fi

	export GIT_COMMITTER_DATE="$(stat -c %y $STAMP)"
	export GIT_AUTHOR_DATE="$GIT_COMMITTER_DATE"
	export GIT_AUTHOR_NAME="Sendmail"
	export GIT_AUTHOR_EMAIL="sendmail@Sendmail.ORG"

	echo "Importing $VERSION"
	echo sendmail | \
	git-import-orig \
		${VERBOSE:+--verbose} \
		--upstream-version $VERSION \
		--upstream-branch="$BRANCH" \
		--upstream-tag="sendmail/%(version)s" \
		--no-merge \
		--no-pristine-tar \
		--interactive \
		$TARBALL
	pristine-tar commit $TARBALL $TAG

	# we only want a lightweight tag
	commit=$(git rev-parse $TAG^{commit})
	git tag -f $TAG $commit

	git checkout $SIGBRANCH
	cp -a $SIG .
	git add $(basename $SIG)
	git commit -m "Imported Upstream version $VERSION"

fi
