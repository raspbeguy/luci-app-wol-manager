# luci-app-wol-manager

LuCI page for [wol-manager](https://github.com/raspbeguy/wol-manager), the Wake-on-LAN HTTP API for OpenWrt with host lists per user.

The page is at `Services > WoL Manager`. It has four sections:

- **Settings**: turn the API on or off, and choose the default interface for the magic packets.
- **Hosts**: name, MAC address (with suggestions from the DHCP leases), and interface.
- **Host lists**: the hosts of each list.
- **Users**: enabled or not, the lists the user can wake, and the token status. The `Generate` button creates a new token and shows it once.

A French translation ships in the `luci-i18n-wol-manager-fr` package.

## Install

Install [wol-manager](https://github.com/raspbeguy/wol-manager) first, or in the same command.

1. Download the apks from the [latest release](https://github.com/raspbeguy/luci-app-wol-manager/releases/latest) and copy them to the router, for example to `/tmp`.
2. Install them:
   ```sh
   apk update
   apk add --allow-untrusted /tmp/luci-app-wol-manager-*.apk /tmp/luci-i18n-wol-manager-fr-*.apk
   ```
3. Restart `rpcd` to load the plugin and the ACL:
   ```sh
   service rpcd restart
   ```

## Access control

The page and the `wol-manager token_new` ubus method need the `luci-app-wol-manager` ACL. root has every ACL. Do not give this ACL to other LuCI accounts: a holder can change every list and create a token for any user.

A token is created by the rpcd plugin on the router. Only its SHA-256 hash is stored, and the page shows the token once.

## Development

```sh
sh scripts/lint.sh        # JSON, JS and ucode syntax, translations, house style
sh scripts/build-apk.sh   # needs SDK_URL and SDK_SHA256, see .github/workflows/ci.yml
```

To try a change, copy `htdocs/` and `root/` onto a router that runs wol-manager and LuCI, run `service rpcd restart`, and reload the page.

When you add or change a translated string, update `po/templates/wol-manager.pot` and `po/fr/wol-manager.po`. The lint fails if a string of the view is missing from the template.

## Releases

A release is a signed tag `vX.Y.Z` that matches `VERSION`. CI verifies the signature against `.github/release-signers.asc`, builds the apks, and attaches them to the GitHub release. The release notes come from the `CHANGELOG.md` section of the version.

The version is independent of wol-manager: a release happens only when this app changes.

## License

[MIT](LICENSE)
