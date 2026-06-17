---
name: rnkit
description: Query and diagnose React Native runtime logs captured by the local ReactNativeKit desktop app through its loopback HTTP API, without MCP. Use when Codex needs to inspect RNKit status, connected apps, filtered application logs, or filtered network responses from a locally running React Native app.
---

# RNKit

Use the bundled `scripts/rnkit.mjs` CLI. Do not call ReactNativeKit MCP tools and do not construct ad hoc HTTP requests.

## Workflow

1. Run `node scripts/rnkit.mjs status` to confirm ReactNativeKit is running.
2. Run `node scripts/rnkit.mjs connections` when multiple apps may be connected. Add `--client-id <id>` to subsequent queries when needed.
3. Query the narrowest useful data:
   - Logs: `node scripts/rnkit.mjs logs --prefix <prefix> [filters]`
   - Network: `node scripts/rnkit.mjs network --url <substring> [filters]`
4. Start with a small limit. Broaden only when the result does not answer the question.
5. Summarize the evidence with timestamps and relevant values. State clearly when no matching event was captured.

The script always queries `http://127.0.0.1:3901`. This loopback address is independent of the phone, simulator, emulator, or LAN IP.

## Log filters

Prefer `--prefix`; add any of:

- `--subprefix <value>`
- `--keyword <text>`
- `--exclude-keyword <text>`
- `--search <text>` for general event searches
- `--type <event-type>`
- `--client-id <id>`
- `--start <ISO timestamp>` and `--end <ISO timestamp>`
- `--limit <1-500>`; default 20
- `--full` only when the complete payload is necessary

Examples:

```bash
node scripts/rnkit.mjs logs --prefix PreviewGateTiming --subprefix finalGatePass --limit 20
node scripts/rnkit.mjs logs --prefix JPush --keyword success --exclude-keyword Registration
node scripts/rnkit.mjs logs --search "fatal" --start 2026-06-17T08:00:00Z --limit 50
```

## Network filters

Require `--url <substring>`. Add any of:

- `--method <GET|POST|PUT|PATCH|DELETE>`
- `--header-name <name>` and optional `--header-value <substring>`
- `--client-id`, `--start`, `--end`, `--limit`
- `--full` to include request and response headers and bodies

```bash
node scripts/rnkit.mjs network --url aiv-vip-plans --method GET --limit 10
```

## Failures

- If the script reports that ReactNativeKit is unavailable, ask the user to start the desktop app. Do not silently start it.
- If a sandbox blocks `127.0.0.1` with `EPERM` or "Operation not permitted", rerun the same script command with the host permission required for loopback access. Do not switch to MCP.
- If multiple apps are connected, list connections and select the intended `clientId`.
- If a query returns no matches, verify the prefix or URL and time range before broadening the query.
