#!/bin/bash
set -eo pipefail

curl --fail http://localhost:$PORT && exit 0
exit 1

