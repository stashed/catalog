#!/bin/bash
set -eou pipefail

REPO_ROOT=$(dirname "${BASH_SOURCE[0]}")/..

echo $(pwd)
echo $REPO_ROOT

HEADER="#!/bin/bash
set -eou pipefail

# This script has been generated automatically by '/partials/build.sh' script.
# Don't modify anything here. Make your desired change in the partial scripts.
# Then, run '/partials/build.sh' script to generate this script with the changes.\n"

# ============ Generate './deploy/script.sh' script ======================
# add common header to the script
echo -e "$HEADER" >"$REPO_ROOT/deploy/script.sh"
# append './partials/catalog.sh' script
cat "$REPO_ROOT/partials/catalogs.sh" >>"$REPO_ROOT/deploy/script.sh"
# append './partials/common.sh' script
cat "$REPO_ROOT/partials/common.sh" >>"$REPO_ROOT/deploy/script.sh"
# append './partials/script.sh' script
cat "$REPO_ROOT/partials/script.sh" >>"$REPO_ROOT/deploy/script.sh"

# ============ Generate './deploy/helm2.sh' script ======================
# add common header to the script
echo -e "$HEADER" >"$REPO_ROOT/deploy/helm2.sh"
# append './partials/catalog.sh' script
cat "$REPO_ROOT/partials/catalogs.sh" >>"$REPO_ROOT/deploy/helm2.sh"
# append './partials/common.sh' script
cat "$REPO_ROOT/partials/common.sh" >>"$REPO_ROOT/deploy/helm2.sh"
# append './partials/helm2.sh' script
cat "$REPO_ROOT/partials/helm2.sh" >>"$REPO_ROOT/deploy/helm2.sh"

# ============ Generate './deploy/helm3.sh' script ======================
# add common header to the script
echo -e "$HEADER" >"$REPO_ROOT/deploy/helm3.sh"
# append './partials/catalog.sh' script
cat "$REPO_ROOT/partials/catalogs.sh" >>"$REPO_ROOT/deploy/helm3.sh"
# append './partials/common.sh' script
cat "$REPO_ROOT/partials/common.sh" >>"$REPO_ROOT/deploy/helm3.sh"
# append './partials/helm3.sh' script
cat "$REPO_ROOT/partials/helm3.sh" >>"$REPO_ROOT/deploy/helm3.sh"

# make generated scripts executable
chmod +x "$REPO_ROOT/deploy/script.sh"
chmod +x "$REPO_ROOT/deploy/helm2.sh"
chmod +x "$REPO_ROOT/deploy/helm3.sh"

echo "Successfully generated deployment scripts"
