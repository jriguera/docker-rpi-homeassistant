#!/usr/bin/env bash
# set -o pipefail  # exit if pipe command fails
[ -z "$DEBUG" ] || set -x
set -e

##

NAME="homeassistant"
DOCKER_TAG="jriguera/$NAME"
RELEASE="homeassistant"
DESCRIPTION="Docker image to run Home Assistant in a Raspberry Pi"
GITHUB_REPO="jriguera/docker-rpi-homeassistant"

###

DOCKER="docker"
JQ="jq"
CURL="curl -s"
RE_VERSION_NUMBER='^[0-9]+([0-9\.]*[0-9]+)*$'

###

ARCH=""
case "$(uname -m)" in
    armv7l)
        ARCH=armhf
        if [ -r /proc/device-tree/model ]
        then
            ARCH='raspberrypi'
            ARCH=${ARCH}$(awk '{ print $3 }' /proc/device-tree/model)
        fi
    ;;
    x86_64|amd64)
        ARCH='amd64'
    ;;
    *)
        echo "ERROR: unsupported architecture: $(uname -m)"
        exit 1
    ;;
esac

VERSION=""
case $# in
    0)
        echo "*** Creating a new release. Automatically calculating version number"
        ;;
    1)
        if [ $1 == "-h" ] || [ $1 == "--help" ]
        then
            echo "Usage:  $0 [version-number]"
            echo "  Creates a release, commits the changes to this repository using tags and uploads "
            echo "  the release to Github Releases and the final Docker image to Docker Hub. "
            echo "  It also adds comments based on previous git commits."
            exit 0
        else
            VERSION=$1
            if ! [[ $VERSION =~ $RE_VERSION_NUMBER ]]
            then
                echo "ERROR: Incorrect version number!"
                exit 1
            fi
            echo "*** Creating a new release. Using release version number $VERSION."
        fi
        ;;
    *)
        echo "ERROR: incorrect argument. See '$0 --help'"
        exit 1
        ;;
esac

# Create a personal github token to use this script
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USER" ]
then
    echo "GITHUB_USER and/or GITHUB_TOKEN environment variables not defined!"
    echo "See https://help.github.com/articles/creating-an-access-token-for-command-line-use/"
    exit 1
fi

# You need bosh installed and with you credentials
if ! [ -x "$(command -v $DOCKER)" ]
then
    echo "ERROR: $DOCKER command not found! Please install it and make it available in the PATH"
    exit 1
fi

# You need jq installed
if ! [ -x "$(command -v $JQ)" ]
then
    echo "ERROR: $JQ command not found! Please install it and make it available in the PATH"
    exit 1
fi

DOCKER_USER=$(docker info 2> /dev/null  | sed -ne 's/Username: \(.*\)/\1/p')
if [ -z "$DOCKER_USER" ]
then
    echo "ERROR: Not logged in Docker Hub!"
    echo "Please perform 'docker login' with your credentials in order to push images there."
    exit 1
fi

# Creating the release
if [ -z "$VERSION" ]
then
    VERSION=$(cd "$(dirname "${BASH_SOURCE[0]}")/home-assistant-core" && git describe --tags | head -n1)
    # VERSION=$(sed -ne 's/^ARG.* VERSION=\(.*\)/\1/p' Dockerfile)
    echo "* Creating final release version $VERSION (from Dockerfile/submodule) ..."
else
    echo "* Creating final release version $VERSION (from input)..."
fi

# Get the last git commit made by this script
LASTCOMMIT=$(git show-ref --tags | awk '{ split($2,tag,"/"); split(tag[3],mytag,"-"); print $1 "." mytag[1] "." mytag[2] }' | sort -t. -k 2,2n -k 3,3n -k 4,4n -k 5,5n | tail -n 1)
if [ -z "$LASTCOMMIT" ]
then
    echo "* Changes since the beginning: "
    CHANGELOG=$(git log --pretty="%h %aI %s (%an)" | sed 's/^/- /')
else
    echo "* Changes since last version with commit $LASTCOMMIT: "
    CHANGELOG=$(git log --pretty="%h %aI %s (%an)" "$(echo $LASTCOMMIT | cut -d'.' -f 1)..@" | sed 's/^/- /')
fi
if [ -z "$CHANGELOG" ]
then
    echo "ERROR: no commits since last release with commit $LASTCOMMIT!. Please "
    echo "commit your changes to create and publish a new release!"
    exit 1
fi
echo "$CHANGELOG"

echo "* Building Docker image with tag $NAME:$VERSION ..."
$DOCKER build \
    --build-arg VERSION=${VERSION} \
    --build-arg ARCH=${ARCH} \
    --build-arg TZ=$(timedatectl  | awk '/Time zone:/{ print $3 }') \
    .  -t $NAME
$DOCKER tag $NAME $DOCKER_TAG

MYVERSION=$(sed -ne 's/^ARG.* MYVERSION=\(.*\)/\1/p' Dockerfile)
[ -n "$MYVERSION" ] && VERSION="$VERSION-$MYVERSION"

# Uploading docker image
echo "* Pusing Docker image to Docker Hub ..."
$DOCKER push $DOCKER_TAG
$DOCKER tag $NAME $DOCKER_TAG:$VERSION
$DOCKER push $DOCKER_TAG

# Save it local
$DOCKER save -o "/tmp/$NAME-$VERSION.tgz" $DOCKER_TAG:$VERSION

# Create annotated tag
echo "* Creating a git tag: $VERSION ... "
git tag -a "$VERSION" -m "$RELEASE v$VERSION"
git push --tags

# Create a release in Github
echo "* Creating a new release in Github ... "
DESC=$(cat <<EOF
# $RELEASE version $VERSION

$DESCRIPTION

## Changes since last version

$CHANGELOG

## Using it

    docker run --name ha -p 8123:8123  -v $(pwd)/config:/config -d jriguera/$RELEASE

EOF
)

printf -v data '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": %s,"draft": false, "prerelease": false}' "$VERSION" "$VERSION" "$(echo "$DESC" | $JQ -R -s '@text')"
releaseid=$($CURL -u "$GITHUB_USER:$GITHUB_TOKEN" -H "Content-Type: application/json" -XPOST --data "$data" "https://api.github.com/repos/$GITHUB_REPO/releases" | $JQ '.id')
# Upload the release
echo "* Uploading image to Github releases section ... "
echo -n "  URL: "
$CURL -u "$GITHUB_USER:$GITHUB_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"/tmp/$NAME-$VERSION.tgz" "https://uploads.github.com/repos/$GITHUB_REPO/releases/$releaseid/assets?name=$NAME-$VERSION.tgz" | $JQ -r '.browser_download_url'

echo
echo "*** Description https://github.com/$GITHUB_REPO/releases/tag/$VERSION: "
echo
echo "$DESC"

# Delete the release
rm -f "/tmp/$NAME-$VERSION.tgz"
git fetch --tags

exit 0
