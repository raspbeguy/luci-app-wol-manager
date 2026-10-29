include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for wol-manager (Wake-on-LAN API with per-user host lists)
LUCI_DEPENDS:=+luci-base +rpcd-mod-ucode +wol-manager
LUCI_PKGARCH:=all
# luci.mk sets MAINTAINER from LUCI_MAINTAINER unconditionally, so a PKG_MAINTAINER
# here is silently dropped and the package ships as "OpenWrt LuCI community".
LUCI_MAINTAINER:=Guy Godfroy <guy.godfroy@gugod.fr>

PKG_VERSION:=$(shell sed -n '1p' $(CURDIR)/VERSION)
PKG_RELEASE:=1
# luci.mk derives the translation version from the git history of po/ in the
# luci feed. This package is built outside that history, which gives version 0
# and translations that never upgrade.
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
