#!/bin/bash

set -eou pipefail

CATALOGS=(
    postgres-stash
)

PG_CATALOG_VERSIONS=(
    9.6
    10.2
    10.6
    11.1
    11.2
)
