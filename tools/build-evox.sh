#!/usr/bin/env bash
# Sync Evolution X (bka), layer the Waydroid patches, build system.img + vendor.img.
# usage: tools/build-evox.sh [src-dir] [sync|patch|build|all]
set -euo pipefail

SRC="${1:-$HOME/evox}"
STEP="${2:-all}"
JOBS="${JOBS:-$(nproc)}"
TARGET="${TARGET:-lineage_waydroid_x86_64-bp4a-userdebug}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$SRC/../waydroid-images}"

die() { echo "error: $*" >&2; exit 1; }

preflight() {
  local c
  for c in git repo python3 curl rsync zip; do
    command -v "$c" >/dev/null || die "missing command: $c"
  done
  git lfs version >/dev/null 2>&1 || die "missing git-lfs"
  git config user.name >/dev/null || die "set git identity: git config --global user.name/user.email (git am needs it)"
  git config user.email >/dev/null || die "set git identity: git config --global user.email"
  mkdir -p "$SRC"
  local free_gb ram_gb
  free_gb=$(df -BG --output=avail "$SRC" | tail -1 | tr -dc 0-9)
  ram_gb=$(awk '/MemTotal/ {printf "%d", $2/1048576}' /proc/meminfo)
  [[ $free_gb -ge 300 ]] || echo "warn: ${free_gb} GB free in $SRC, a full tree plus out/ wants ~300 GB"
  [[ $ram_gb -ge 16 ]] || echo "warn: ${ram_gb} GB RAM, kati gets SIGKILLed under 16 GB even with swap"
}

do_sync() {
  cd "$SRC"
  [[ -d .repo ]] || repo init -u https://github.com/Evolution-X/manifest -b bka --git-lfs
  # install our manifest fragments first so the swapped-out projects are never fetched
  (cd "$HERE" && ./waydroid-patches.sh manifest "$SRC" --no-sync)
  repo sync -c -j"$JOBS" --force-sync --no-clone-bundle --no-tags
}

do_patch() {
  cd "$HERE"
  ./waydroid-patches.sh manifest "$SRC" --no-sync
  ./waydroid-patches.sh apply "$SRC" --no-sync
  python3 tools/check-dup-modules.py "$SRC" --ours manifest/10-waydroid-projects.xml
  ./waydroid-patches.sh status "$SRC"
}

do_build() {
  cd "$SRC"
  repo manifest -o /dev/null   # avoids the read-only ~/.repo_.gitconfig.json rewrite inside soong
  bash -c ". build/envsetup.sh && lunch '$TARGET' && mka systemimage vendorimage -j$JOBS"
  local pdir
  pdir=$(find out/target/product -maxdepth 1 -type d -name 'waydroid*' | head -1)
  [[ -n "$pdir" ]] || die "no waydroid product dir under out/target/product"
  mkdir -p "$OUT"
  cp -v "$pdir/system.img" "$pdir/vendor.img" "$OUT/"
  cat <<EOT

images in $OUT, install:
  sudo mkdir -p /etc/waydroid-extra/images
  sudo cp $OUT/system.img $OUT/vendor.img /etc/waydroid-extra/images/
  sudo chmod 644 /etc/waydroid-extra/images/*.img
  sudo rm -rf /var/lib/waydroid && sudo waydroid init -f
  sudo systemctl enable --now waydroid-container
EOT
}

preflight
case "$STEP" in
  sync)  do_sync ;;
  patch) do_patch ;;
  build) do_build ;;
  all)   do_sync; do_patch; do_build ;;
  *)     die "step must be sync|patch|build|all" ;;
esac
