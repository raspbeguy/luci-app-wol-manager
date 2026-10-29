# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/), and the project adheres to
[Semantic Versioning](https://semver.org/).

Versioning is independent of wol-manager: a release happens only when this app
changes, never because wol-manager was bumped.

## [Unreleased]

### Added

- Page `Services > WoL Manager`: settings, hosts, host lists, users and the lists each user can wake.
- `Generate` button: creates a token through the `wol-manager` rpcd plugin and shows it once.
- ACL `luci-app-wol-manager`, limited to the `wol_manager` configuration, host hints and `token_new`.
- French translation.
