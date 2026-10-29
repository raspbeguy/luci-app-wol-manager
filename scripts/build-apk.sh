#!/bin/sh
# Build the luci-app-wol-manager apks against a pinned OpenWrt SDK.
#
# Two wrinkles drive the shape of this script:
#   1. The Makefile does `include ../../luci.mk`, which only resolves inside the
#      luci feed tree, so the package is copied into feeds/luci/applications/.
#   2. An apk is only kept in bin/ when its package is SELECTED, and selecting
#      luci-app-wol-manager requires its `wol-manager` dependency to exist as a
#      known package. The real wol-manager lives in a sibling repo, so a
#      build-time STUB named `wol-manager` satisfies the dependency symbol. The
#      stub is never published; the `depends: wol-manager` metadata of the app
#      is correct regardless.
#
# Inputs (env):
#   SDK_URL     full URL of the SDK tarball (.tar.zst)         [required]
#   SDK_SHA256  expected sha256 of that tarball                [required]
#   SDK_DIR     extract/cache location (default: $REPO/.sdk)
#   DIST_DIR    where the apks are copied (default: $REPO/dist)
# Output:
#   the app apk and its translation apks in DIST_DIR; also writes
#   `dist=<dir>` to $GITHUB_OUTPUT when running under GitHub Actions.
set -eu

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
SDK_DIR=${SDK_DIR:-"$REPO_DIR/.sdk"}
DIST_DIR=${DIST_DIR:-"$REPO_DIR/dist"}
: "${SDK_URL:?SDK_URL required}"
: "${SDK_SHA256:?SDK_SHA256 required}"

TARBALL=$(basename "$SDK_URL")
TMP=${TMPDIR:-/tmp}

if [ ! -d "$SDK_DIR/staging_dir" ]; then
	echo "Downloading SDK: $SDK_URL"
	mkdir -p "$SDK_DIR"
	curl -fsSL -o "$TMP/$TARBALL" "$SDK_URL"
	echo "$SDK_SHA256  $TMP/$TARBALL" | sha256sum -c -
	tar --use-compress-program=unzstd -xf "$TMP/$TARBALL" -C "$SDK_DIR" --strip-components=1
	rm -f "$TMP/$TARBALL"
fi

cd "$SDK_DIR"

./scripts/feeds update -a >/dev/null 2>&1 || ./scripts/feeds update -a

mkdir -p package/wol-manager-dep-stub
cat > package/wol-manager-dep-stub/Makefile <<'STUB'
include $(TOPDIR)/rules.mk
PKG_NAME:=wol-manager
PKG_VERSION:=0
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk
define Package/wol-manager
  SECTION:=net
  CATEGORY:=Network
  TITLE:=wol-manager (CI build-dependency stub, do not publish)
endef
define Build/Compile
endef
define Package/wol-manager/install
endef
$(eval $(call BuildPackage,wol-manager))
STUB

DEST=feeds/luci/applications/luci-app-wol-manager
rm -rf "$DEST"
mkdir -p "$DEST"
for item in Makefile VERSION LICENSE htdocs root po; do
	cp -r "$REPO_DIR/$item" "$DEST/"
done

./scripts/feeds update -i >/dev/null 2>&1
./scripts/feeds install -p luci luci-app-wol-manager >/dev/null

for pkg in luci-app-wol-manager luci-i18n-wol-manager-fr; do
	grep -q "^CONFIG_PACKAGE_$pkg=y" .config 2>/dev/null \
		|| echo "CONFIG_PACKAGE_$pkg=y" >> .config
done
make defconfig >/dev/null

# defconfig turns the translation into `m`, which the SDK builds and keeps in bin/ too.
for pkg in luci-app-wol-manager luci-i18n-wol-manager-fr; do
	if ! grep -Eq "^CONFIG_PACKAGE_$pkg=[ym]" .config; then
		echo "ERROR: $pkg could not be selected (dependency unresolved)." >&2
		exit 1
	fi
done

# A cached SDK keeps the apks of the previous build in bin/; remove them so the
# lookup below cannot return a stale file.
find bin \( -name 'luci-app-wol-manager-*.apk' -o -name 'luci-i18n-wol-manager-*.apk' \) -delete 2>/dev/null || true

make package/luci-app-wol-manager/compile V=s

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
find bin \( -name 'luci-app-wol-manager-*.apk' -o -name 'luci-i18n-wol-manager-*.apk' \) -exec cp {} "$DIST_DIR/" \;
ls "$DIST_DIR"/luci-app-wol-manager-*.apk >/dev/null 2>&1 || { echo "ERROR: no luci-app-wol-manager apk produced" >&2; exit 1; }
ls "$DIST_DIR"/luci-i18n-wol-manager-fr-*.apk >/dev/null 2>&1 || { echo "ERROR: no French translation apk produced" >&2; exit 1; }

sha256sum "$DIST_DIR"/*.apk
[ -n "${GITHUB_OUTPUT:-}" ] && echo "dist=$DIST_DIR" >> "$GITHUB_OUTPUT"
echo "$DIST_DIR"
