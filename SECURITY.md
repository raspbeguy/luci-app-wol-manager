# Security policy

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: **[Report a vulnerability](https://github.com/raspbeguy/luci-app-wol-manager/security/advisories/new)**.

Expect a first response within a week. That is a rough figure rather than an SLA.

## What counts as a vulnerability here

The page edits the wol-manager configuration and creates API tokens, so the boundary is the `luci-app-wol-manager` ACL.

- A LuCI account without this ACL that can read or change the `wol_manager` configuration, or call `token_new`.
- A token reaching anywhere it should not: a log, a URL, another origin, or a later page view.
- Markup injection: a uci value rendered without escaping, so a hostile value stored on the router runs as script for the next operator who opens the page.

## Out of scope

- What the wol-manager API accepts or refuses. Report that to [wol-manager](https://github.com/raspbeguy/wol-manager/security/advisories/new).
- LuCI's own session handling and authentication.
- An operator with root on the router doing something destructive through the page on purpose.

## Supported versions

The current release only. Fixes ship as a new version rather than as backports.
