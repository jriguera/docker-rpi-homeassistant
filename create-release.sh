#!/usr/bin/env bash
# set -o pipefail  # exit if pipe command fails
[ -z "$DEBUG" ] || set -x
set -e

##

NAME="homeassistant"
RELEASE="rpi-homeassistant"
DESCRIPTION="Docker image to run Home Assistant in a Raspberry Pi"
GITHUB_REPO="jriguera/docker-rpi-homeassistant"

###

DOCKER=docker
JQ=jq
CURL="curl -s"

RE_VERSION_NUMBER='^[0-9]+([0-9\.]*[0-9]+)*$'


# Create a personal github token to use this script
if [ -z "$GITHUB_TOKEN" ]
then
    echo "Github TOKEN not defined!"
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

DOCKER_USER=$(docker info 2> /dev/null  | sed -ne 's/^Username: \(.*\)/\1/p')
if [ -z "$DOCKER_USER" ]
then
    echo "ERROR: Not logged in Docker Hub!"
    echo "Please perform 'docker login' with your credentials in order to push images there."
    exit 1
fi

VERSION=""
case $# in
    0)
        echo "*** Creating a new release. Automatically calculating next release version number"
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

# Creating the release
if [ -z "$VERSION" ]
then
    VERSION=$(sed -ne 's/^ARG.*VERSION=\(.*\)/\1/p' Dockerfile)
    echo "* Creating final release version $VERSION (from Dockerfile) ..."
else
    echo "* Creating final release version $VERSION (from input)..."
fi

# Get the last git commit made by this script
lastcommit=$(git log --format="%h" --grep="$RELEASE v*" | head -1)
echo "* Changes since last version with commit $lastcommit: "
git_changes=$(git log --pretty="%h %aI %s (%an)" $lastcommit..@ | sed 's/^/- /')
if [ -z "$git_changes" ]
then
    echo "ERROR: no commits since last release with commit $lastcommit!. Please "
    echo "commit your changes to create and publish a new release!"
    exit 1
fi
echo "$git_changes"

echo "* Building Docker image with tag $NAME ..."
$DOCKER build . -t $NAME

# Uploading docker image
echo "* Pusing Docker image to Docker Hub ..."
$DOCKER push $RELEASE:$NAME

# Create a new tag and update the changes
echo "* Commiting git changes ..."
git add *
git commit -m "$RELEASE v$VERSION"
git push --tags

# Create a release in Github
echo "* Creating a new release in Github ... "
DESC=$(cat <<EOF
# $RELEASE version $VERSION

$DESCRIPTION

## Changes since last version

$git_changes

## Using in a bosh Deployment

    docker run --name ha -p 8123:8123  -v $(pwd)/config:/config -d jriguera/$RELEASE

EOF
)
printf -v DATA '{"tag_name": "v%s","target_commitish": "master","name": "v%s","body": %s,"draft": false, "prerelease": false}' "$VERSION" "$VERSION" "$(echo "$DESC" | $JQ -R -s '@text')"
$CURL -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" -XPOST --data "$DATA" "https://api.github.com/repos/$GITHUB_REPO/releases" > /dev/null

echo
echo "*** Description https://github.com/$GITHUB_REPO/releases/tag/v$VERSION: "
echo
echo "$description"

exit 0

