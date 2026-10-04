# Evolution X (bka, Android 16)

Branch `EvolutionX-bka`. Same layout as `lineage-23.2`; Evolution X `bka` is
LineageOS 23.2 based with its own forks, so only the patches below differ.

## Build (needs a PC: ~300 GB disk, 16+ GB RAM)

    git clone -b EvolutionX-bka https://github.com/<you>/WayDroid_Patches
    cd WayDroid_Patches
    git config --global user.name  "you"      # git am needs an identity
    git config --global user.email "you@example.com"
    tools/build-evox.sh ~/evox all            # or: sync | patch | build

Images land in `~/waydroid-images/{system,vendor}.img`. Install:

    sudo mkdir -p /etc/waydroid-extra/images
    sudo cp ~/waydroid-images/*.img /etc/waydroid-extra/images/
    sudo chmod 644 /etc/waydroid-extra/images/*.img
    sudo rm -rf /var/lib/waydroid && sudo waydroid init -f
    sudo systemctl enable --now waydroid-container

`TARGET=... tools/build-evox.sh` overrides the lunch target
(default `lineage_waydroid_x86_64-bp4a-userdebug`, untested on Evolution X: if
`lunch` rejects it, run `lunch` with no args and pick the waydroid x86_64 entry).

## What differs from `lineage-23.2`

Rebased by hand against Evolution-X `bka` forks (patch dry-run verified):

| Patch | Why |
|---|---|
| frameworks/base 0006, 0012, 0017 | context moved (Evolution deps/imports/proguard) |
| frameworks/base 0016 | `DisplayModeDirector` min-refresh default changed (60f) |
| frameworks/base 0014 (dropped) | Evolution already `#if 0`s the `createProcessGroup` fail_fn |
| system/core 0007 | `init.rc` post-fs-data block moved |
| system/core 0017 | merged with Evolution's `weaken_prop_override_security` ro.* guard |
| system/core 0026 | `SFMainPolicy`/`SFRenderEnginePolicy` use cpuset path `foreground` |
| build/soong 0002, 0004 | `package_allowed_list.txt` tail, PATH allowlist (no `tar`/`date` anchor) |
| Settings 0001 | `firmware_version.xml` has `LineageBuildDate` after Kernel |
| Connectivity 0001 | `NetdUpdatable.cpp` abort already replaced by a log |
| sepolicy 0001 | only the two `aux` lines exist; `skip_unconfigure` line kept |

`lineage-sdk` 20-upstream/0001 is already contained in Evolution's fork; the
script skips it (reverse-apply check).

## Not verified (needs a real tree)

- full `mka systemimage vendorimage`
- soong `module already defined` clashes (run `tools/check-dup-modules.py`)
- boot on a real Waydroid host
