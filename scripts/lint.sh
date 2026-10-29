#!/bin/sh
# Static checks for the LuCI app: house style, JSON, JS and ucode syntax,
# translations, VERSION. No OpenWrt toolchain required; runs anywhere with
# ucode, node and gettext. Used by CI (lint job) and runnable locally.
set -eu

cd "$(dirname "$0")/.."
fail=0

note() { printf '%s\n' "$*"; }

# House style: no em-dashes. grep rather than `git ls-files`, because the CI
# container has no git and the check would pass silently on an empty file list.
EMDASH=$(printf '\342\200\224')
if grep -rnI --exclude-dir=.git --exclude-dir=.sdk "$EMDASH" .; then
	note "FAIL: em-dash found (house style forbids em-dashes; use ': ' or '(...)')"
	fail=1
fi

for f in $(find root -name '*.json'); do
	if ! node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" 2>/tmp/json.err; then
		note "FAIL: invalid JSON: $f"; cat /tmp/json.err; fail=1
	fi
done

# node parses CommonJS, so the view's top-level `return` is allowed.
for f in $(find htdocs -name '*.js'); do
	if ! node --check "$f" 2>/tmp/js.err; then
		note "FAIL: JS syntax: $f"; cat /tmp/js.err; fail=1
	fi
done

# The rpcd plugin imports wol_manager, which only exists on the router, so the
# import line is stripped before the compile check.
for f in $(find root -name '*.uc'); do
	tmp=$(mktemp)
	sed "/^import .* from '[a-z_]*';\$/d" "$f" > "$tmp"
	if ! ucode -c -o /dev/null "$tmp" 2>/tmp/uc.err; then
		note "FAIL: ucode syntax: $f"; cat /tmp/uc.err; fail=1
	fi
	rm -f "$tmp"
done

# Every string the view translates must be in the template, or it never reaches
# translators.
msgids=$(mktemp)
grep -rohE "_\('[^']+'\)" htdocs | sed "s/^_('//; s/')\$//" | sort -u > "$msgids"
while IFS= read -r msgid; do
	if ! grep -qxF "msgid \"$msgid\"" po/templates/wol-manager.pot; then
		note "FAIL: missing from po/templates/wol-manager.pot: $msgid"; fail=1
	fi
done < "$msgids"
rm -f "$msgids"

for f in po/*/*.po; do
	if ! msgfmt -c -o /dev/null "$f" 2>/tmp/po.err; then
		note "FAIL: invalid translation: $f"; cat /tmp/po.err; fail=1
	fi
done

VER=$(sed -n '1p' VERSION)
if ! printf '%s' "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
	note "FAIL: VERSION must be a single x.y.z line, got: '$VER'"
	fail=1
fi

[ "$fail" = 0 ] && note "lint: OK"
exit "$fail"
