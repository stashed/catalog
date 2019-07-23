#!/bin/bash
set -eou pipefail

GOPATH=$(go env GOPATH)
REPO_ROOT=$GOPATH/src/stash.appscode.dev/catalog

HEADER="#!/bin/bash
set -eou pipefail

# This script has been generated automatically by '/partials/build.sh' script.
# Don't modify anything here. Make your desired change in the partial scripts.
# Then, run '/partials/build.sh' script to generate this script with the changes.\n"

# ============ Generate './deploy/script.sh' script ======================
# add common header to the script
echo -e "$HEADER" >"$REPO_ROOT/deploy/script.sh"
# append './partials/catalog.sh' script
cat "$REPO_ROOT/partials/catalogs.sh" >> "$REPO_ROOT/deploy/script.sh"
# append './partials/common.sh' script
cat "$REPO_ROOT/partials/common.sh" >> "$REPO_ROOT/deploy/script.sh"
# append './partials/script.sh' script
cat "$REPO_ROOT/partials/script.sh" >> "$REPO_ROOT/deploy/script.sh"

# ============ Generate './deploy/chart.sh' script ======================
# add common header to the script
echo -e "$HEADER" >"$REPO_ROOT/deploy/chart.sh"
# append './partials/catalog.sh' script
cat "$REPO_ROOT/partials/catalogs.sh" >> "$REPO_ROOT/deploy/chart.sh"
# append './partials/common.sh' script
cat "$REPO_ROOT/partials/common.sh" >> "$REPO_ROOT/deploy/chart.sh"
# append './partials/chart.sh' script
cat "$REPO_ROOT/partials/chart.sh" >> "$REPO_ROOT/deploy/chart.sh"

# make generated scripts executable
chmod +x "$REPO_ROOT/deploy/script.sh"
chmod +x "$REPO_ROOT/deploy/chart.sh"

echo "Successfully generated deployment scripts"