#!/bin/bash
set -eou pipefail

GOPATH=$(go env GOPATH)
REPO_ROOT=$GOPATH/src/stash.appscode.dev/catalog

source "$REPO_ROOT/deploy/common.sh"



