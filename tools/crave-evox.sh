#!/usr/bin/env bash
# Runs ON a Crave build node (inside `crave run --no-patch -- ...`) from the root of the source dir.
# Evolution X bka + Waydroid patches -> system.img + vendor.img in out/waydroid-images/
set -euo pipefail

FORK="${FORK:-https://github.com/ILYESwsa/WayDroid_Patches}"
BRANCH="${BRANCH:-EvolutionX-bka}"
TARGET="${TARGET:-lineage_waydroid_x86_64-bp4a-userdebug}"
SRC="$PWD"
WDP=/tmp/WayDroid_Patches

git config --global user.name  "${GIT_NAME:-crave}"
git config --global user.email "${GIT_EMAIL:-crave@localhost}"

rm -rf .repo/local_manifests "$WDP"
repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs
git clone --depth 1 -b "$BRANCH" "$FORK" "$WDP"

# our manifest fragments first (swaps + extra projects), then Crave's fast resync
"$WDP/waydroid-patches.sh" manifest "$SRC" --no-sync
/opt/crave/resync.sh

"$WDP/waydroid-patches.sh" apply "$SRC" --no-sync
python3 "$WDP/tools/check-dup-modules.py" "$SRC" --ours "$WDP/manifest/10-waydroid-projects.xml"
"$WDP/waydroid-patches.sh" status "$SRC"

repo manifest -o /dev/null
source build/envsetup.sh
lunch "$TARGET"
mka systemimage vendorimage

pdir=$(find out/target/product -maxdepth 1 -type d -name 'waydroid*' | head -1)
mkdir -p out/waydroid-images
cp -v "$pdir/system.img" "$pdir/vendor.img" out/waydroid-images/
