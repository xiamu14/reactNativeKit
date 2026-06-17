const http = require("http")
const path = require("path")
const { queryLogs, queryNetwork } = require("./query")

const repoRoot = path.resolve(__dirname, "../../..")
const compatibilityRoot = path.join(repoRoot, "packages/reactotron")
const { createServer } = require(path.join(
  compatibilityRoot,
  "lib/reactotron-core-server/dist/commonjs"
))
const { createMcpServer } = require(path.join(compatibilityRoot, "lib/reactotron-mcp/dist"))

const config = {
  serverPort: readPort("REACTOTRON_SERVER_PORT", 9091),
  apiPort: readPort("REACTOTRON_NATIVE_API_PORT", 3901),
  mcpPort: readPort("REACTOTRON_MCP_PORT", 4567),
  bufferLimit: readPositiveInt("REACTOTRON_BUFFER_LIMIT", 2000),
}

const state = {
  startedAt: new Date().toISOString(),
  serverStatus: "starting",
  mcpStatus: "starting",
  connections: new Map(),
  commands: [],
  portUnavailable: null,
}

let reactotronServer = null
let mcpServer = null
let mcpStartPromise = null
let mcpEnsureInterval = null
let runtimeStartPromise = null
let runtimeEnsureInterval = null

function readPort(name, fallback) {
  const value = Number.parseInt(process.env[name] || "", 10)
  return Number.isInteger(value) && value > 0 && value < 65536 ? value : fallback
}

function readPositiveInt(name, fallback) {
  const value = Number.parseInt(process.env[name] || "", 10)
  return Number.isInteger(value) && value > 0 ? value : fallback
}

function normalizeConnection(connection, connected) {
  const previous = state.connections.get(connection.clientId) || {}
  return {
    id: connection.id,
    clientId: connection.clientId,
    name: connection.name || previous.name || "React Native App",
    platform: connection.platform || previous.platform || "unknown",
    platformVersion: optionalString(connection.platformVersion ?? previous.platformVersion),
    osRelease: optionalString(connection.osRelease ?? previous.osRelease),
    userAgent: optionalString(connection.userAgent ?? previous.userAgent),
    address: optionalString(connection.address ?? previous.address),
    connected,
    lastSeenAt: new Date().toISOString(),
  }
}

function optionalString(value) {
  if (value == null || value === "") return null
  return String(value)
}

function normalizeTargetPart(value) {
  return String(value || "").trim().toLowerCase()
}

function connectionTargetKey(connection) {
  return [
    connection.name,
    connection.platform,
    connection.platformVersion,
    connection.osRelease,
    connection.userAgent,
    connection.address,
  ].map(normalizeTargetPart).join("|")
}

function connectionTime(connection) {
  const time = Date.parse(connection.lastSeenAt || "")
  return Number.isNaN(time) ? 0 : time
}

function visibleConnections() {
  const deduped = new Map()
  for (const connection of state.connections.values()) {
    const key = connectionTargetKey(connection)
    const previous = deduped.get(key)
    if (!previous) {
      deduped.set(key, connection)
      continue
    }

    const shouldReplace =
      (connection.connected && !previous.connected) ||
      (connection.connected === previous.connected && connectionTime(connection) >= connectionTime(previous))

    if (shouldReplace) {
      deduped.set(key, connection)
    }
  }

  return Array.from(deduped.values()).sort((left, right) => {
    if (left.connected !== right.connected) return left.connected ? -1 : 1
    return connectionTime(right) - connectionTime(left)
  })
}

function upsertConnection(connection, connected) {
  const normalized = normalizeConnection(connection, connected)
  const targetKey = connectionTargetKey(normalized)

  if (connected) {
    for (const [clientId, existing] of state.connections.entries()) {
      if (clientId !== normalized.clientId && connectionTargetKey(existing) === targetKey) {
        state.connections.delete(clientId)
      }
    }
  }

  state.connections.set(normalized.clientId, normalized)
}

function safeStringify(value) {
  if (value == null) return ""
  if (typeof value === "string") return value
  try {
    return JSON.stringify(value)
  } catch {
    return String(value)
  }
}

function prettyStringify(value) {
  if (value == null || value === "") return ""
  if (typeof value === "string") return value
  try {
    return JSON.stringify(value, null, 2)
  } catch {
    return String(value)
  }
}

function pushDetail(lines, title, value) {
  const text = prettyStringify(value)
  if (!text) return
  lines.push(`${title}:\n${text}`)
}

function commandSummary(command) {
  const payload = command.payload || {}

  if (command.type === "log") {
    return safeStringify(payload.message || payload)
  }

  if (command.type === "api.response") {
    const method = payload.request?.method || payload.method || "HTTP"
    const url = payload.request?.url || payload.url || ""
    const status = payload.response?.status || payload.status || ""
    return `${method} ${url}${status ? ` (${status})` : ""}`.trim()
  }

  if (command.type === "client.intro") {
    return `${payload.name || "App"} connected`
  }

  return safeStringify(payload)
}

function commandDetails(command) {
  const payload = command.payload || {}

  if (command.type === "api.response") {
    const request = payload.request || {}
    const response = payload.response || {}
    const method = request.method || payload.method || "HTTP"
    const url = request.url || payload.url || ""
    const status = response.status || payload.status || ""
    const lines = [`${method} ${url}${status ? ` (${status})` : ""}`.trim()]

    pushDetail(lines, "Request headers", request.headers || payload.requestHeaders)
    pushDetail(lines, "Request body", request.body ?? request.data ?? payload.requestBody)
    pushDetail(lines, "Response headers", response.headers || payload.responseHeaders)
    pushDetail(lines, "Response body", response.body ?? response.data ?? payload.responseBody)

    return lines.join("\n\n")
  }

  return prettyStringify(payload) || commandSummary(command)
}

function normalizeCommand(command) {
  return {
    messageId: command.messageId,
    connectionId: command.connectionId,
    clientId: command.clientId || null,
    type: command.type || "unknown",
    important: Boolean(command.important),
    date: new Date(command.date || Date.now()).toISOString(),
    deltaTime: Number(command.deltaTime || 0),
    summary: commandSummary(command),
    details: commandDetails(command),
    payload: command.payload || null,
  }
}

function allCommands() {
  return state.commands.slice().sort((left, right) => left.messageId - right.messageId)
}

function writeJson(res, statusCode, payload) {
  const body = JSON.stringify(payload)
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "http://127.0.0.1",
    "Cache-Control": "no-store",
  })
  res.end(body)
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    let body = ""
    req.on("data", (chunk) => {
      body += chunk
      if (body.length > 1_000_000) {
        reject(new Error("Request body too large"))
        req.destroy()
      }
    })
    req.on("end", () => resolve(body))
    req.on("error", reject)
  })
}

function statusPayload() {
  const connections = visibleConnections()
  return {
    ok: state.serverStatus === "started",
    startedAt: state.startedAt,
    serverStatus: state.serverStatus,
    serverPort: config.serverPort,
    apiPort: config.apiPort,
    mcpStatus: state.mcpStatus,
    mcpPort: config.mcpPort,
    connectionCount: connections.filter((connection) => connection.connected).length,
    totalKnownConnections: connections.length,
    logCount: state.commands.length,
    bufferLimit: config.bufferLimit,
    portUnavailable: state.portUnavailable,
  }
}

async function requestHandler(req, res) {
  if (req.method === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "http://127.0.0.1",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    })
    res.end()
    return
  }

  const url = new URL(req.url || "/", `http://${req.headers.host || "127.0.0.1"}`)

  if (req.method === "GET" && url.pathname === "/health") {
    writeJson(res, 200, { ok: true, service: "reactkit-native-backend" })
    return
  }

  if (req.method === "GET" && url.pathname === "/status") {
    writeJson(res, 200, statusPayload())
    return
  }

  if (req.method === "GET" && url.pathname === "/connections") {
    writeJson(res, 200, { connections: visibleConnections() })
    return
  }

  if (req.method === "GET" && url.pathname === "/logs") {
    writeJson(res, 200, { logs: queryLogs(state.commands, url.searchParams) })
    return
  }

  if (req.method === "GET" && url.pathname === "/network") {
    writeJson(res, 200, { entries: queryNetwork(state.commands, url.searchParams) })
    return
  }

  if (req.method === "POST" && url.pathname === "/clear") {
    const body = await readRequestBody(req)
    const payload = body ? JSON.parse(body) : {}
    const clientId = payload.clientId || url.searchParams.get("clientId")

    if (clientId) {
      state.commands = state.commands.filter((command) => command.clientId !== clientId)
    } else {
      state.commands = []
    }

    writeJson(res, 200, { ok: true, clearedClientId: clientId || null })
    return
  }

  if (req.method === "GET" && url.pathname === "/mcp/status") {
    writeJson(res, 200, {
      status: state.mcpStatus,
      port: config.mcpPort,
      started: Boolean(mcpServer?.started),
    })
    return
  }

  if (req.method === "POST" && url.pathname === "/mcp/start") {
    await ensureMcpServer()
    writeJson(res, 200, {
      status: state.mcpStatus,
      port: config.mcpPort,
      started: Boolean(mcpServer?.started),
    })
    return
  }

  writeJson(res, 404, { error: "Not found" })
}

function startRuntimeServer() {
  if (state.serverStatus === "started") {
    return Promise.resolve()
  }

  if (runtimeStartPromise) {
    return runtimeStartPromise
  }

  state.serverStatus = "starting"
  state.portUnavailable = null

  if (reactotronServer) {
    try {
      reactotronServer.stop()
    } catch {}
  }

  reactotronServer = createServer({ port: config.serverPort })

  reactotronServer.on("start", () => {
    state.serverStatus = "started"
    state.portUnavailable = null
  })

  reactotronServer.on("stop", () => {
    if (state.serverStatus !== "stopping") {
      state.serverStatus = "stopped"
    }
  })

  reactotronServer.on("portUnavailable", (port) => {
    state.serverStatus = "portUnavailable"
    state.portUnavailable = port
  })

  reactotronServer.on("connectionEstablished", (connection) => {
    upsertConnection(connection, true)
  })

  reactotronServer.on("disconnect", (connection) => {
    upsertConnection(connection, false)
  })

  reactotronServer.on("command", (command) => {
    const normalized = normalizeCommand(command)
    state.commands.push(normalized)
    if (state.commands.length > config.bufferLimit) {
      state.commands.splice(0, state.commands.length - config.bufferLimit)
    }
  })

  runtimeStartPromise = new Promise((resolve) => {
    let settled = false
    const finish = () => {
      if (settled) return
      settled = true
      resolve()
    }

    reactotronServer.on("start", finish)
    reactotronServer.on("portUnavailable", finish)
    setTimeout(finish, 500)

    reactotronServer.start()
  }).finally(() => {
    runtimeStartPromise = null
  })

  return runtimeStartPromise
}

function createRequiredMcpServer() {
  return createMcpServer(reactotronServer, {
    clearTimeline: (clientId) => {
      if (clientId) {
        state.commands = state.commands.filter((command) => command.clientId !== clientId)
      } else {
        state.commands = []
      }
    },
    getCommands: allCommands,
  })
}

function ensureMcpServer() {
  if (mcpServer?.started) {
    state.mcpStatus = "started"
    config.mcpPort = mcpServer.port || config.mcpPort
    return Promise.resolve()
  }

  if (mcpStartPromise) {
    return mcpStartPromise
  }

  state.mcpStatus = "starting"

  mcpStartPromise = startMcpWithFallback(config.mcpPort)
    .then(() => {
      state.mcpStatus = "started"
      config.mcpPort = mcpServer.port || config.mcpPort
    })
    .catch((error) => {
      state.mcpStatus = "error"
      console.error("[reactkit-backend] MCP failed to start:", error)
    })
    .finally(() => {
      mcpStartPromise = null
    })

  return mcpStartPromise
}

async function startMcpWithFallback(firstPort) {
  let lastError = null
  for (let port = firstPort; port < firstPort + 20; port += 1) {
    const candidate = createRequiredMcpServer()
    try {
      await candidate.start(port)
      mcpServer = candidate
      return
    } catch (error) {
      lastError = error
      candidate.stop()
      const isPortConflict = error?.code === "EADDRINUSE" || String(error?.message || error).includes("EADDRINUSE")
      if (!isPortConflict) {
        throw error
      }
    }
  }
  throw lastError || new Error("No available MCP port")
}

function startApiServer() {
  const apiServer = http.createServer((req, res) => {
    requestHandler(req, res).catch((error) => {
      writeJson(res, error.statusCode || 500, { error: String(error.message || error) })
    })
  })

  apiServer.listen(config.apiPort, "127.0.0.1", () => {
    console.log(
      `[reactkit-backend] API http://127.0.0.1:${config.apiPort}, runtime :${config.serverPort}, MCP :${config.mcpPort}`
    )
  })

  return apiServer
}

function shutdown(apiServer) {
  state.serverStatus = "stopping"
  state.mcpStatus = "stopping"
  if (mcpEnsureInterval) clearInterval(mcpEnsureInterval)
  if (runtimeEnsureInterval) clearInterval(runtimeEnsureInterval)
  if (mcpServer) mcpServer.stop()
  if (reactotronServer) reactotronServer.stop()
  apiServer.close(() => process.exit(0))
}

void startRuntimeServer()
runtimeEnsureInterval = setInterval(() => {
  if (state.serverStatus !== "started") {
    void startRuntimeServer()
  }
}, 3000)
void ensureMcpServer()
mcpEnsureInterval = setInterval(() => {
  void ensureMcpServer()
}, 3000)
const apiServer = startApiServer()

process.on("SIGINT", () => shutdown(apiServer))
process.on("SIGTERM", () => shutdown(apiServer))
