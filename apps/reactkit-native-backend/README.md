# ReactKit Native Backend

Small local backend used by the SwiftUI macOS shell.

This backend currently reuses the Reactotron protocol packages from `packages/reactotron`.
Build those packages before starting ReactKit on a fresh machine.

## Run

```bash
node apps/reactkit-native-backend/src/index.js
```

Environment variables:

- `REACTOTRON_SERVER_PORT`, default `9091`
- `REACTOTRON_NATIVE_API_PORT`, default `3901`
- `REACTOTRON_MCP_PORT`, default `4567`
- `REACTOTRON_BUFFER_LIMIT`, default `2000`

## API

- `GET /health`
- `GET /status`
- `GET /connections`
- `GET /logs?clientId=...&search=...&type=...&prefix=...&subprefix=...&keyword=...&excludeKeyword=...&start=...&end=...&limit=...`
- `GET /network?url=...&method=...&headerName=...&headerValue=...&clientId=...&start=...&end=...&limit=...`
- `POST /clear`
- `GET /mcp/status`
- `POST /mcp/start`

MCP is required for the desktop app lifecycle. The backend starts it automatically, keeps retrying while the app is running, and stops it only when the app exits.
