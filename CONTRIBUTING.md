# Contributing to luci-app-wol-manager

## What this is

A LuCI page for [wol-manager](https://github.com/raspbeguy/wol-manager): a client-side view under `htdocs/luci-static/`, an rpcd plugin that creates tokens, an ACL, and translations.

## Dev loop

There is no build step for the view. It is plain JavaScript loaded by LuCI, so the loop is: edit, copy onto a router that already runs wol-manager and LuCI, and reload the page.

```sh
sh scripts/lint.sh        # what CI gates on: JSON, JS and ucode syntax, translations, house style
sh scripts/build-apk.sh   # builds the packages against the OpenWrt SDK
```

## What kinds of changes are welcome

- Translations: add `po/<lang>/wol-manager.po`.
- Anything that makes the page clearer about who can wake what.
- Anything that narrows the ACL.

## Style

No em-dashes anywhere. Comments explain why, not what.

## Commit and PR style

One-line subject in the imperative. Explain in the body why the change is needed rather than restating the diff. Every change lands via a pull request.
