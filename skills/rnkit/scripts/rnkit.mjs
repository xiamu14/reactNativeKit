#!/usr/bin/env node

const BASE_URL = "http://127.0.0.1:3901"
const COMMANDS = new Set(["status", "connections", "logs", "network"])

function usage() {
  return `RNKit local query CLI (no MCP)

Usage:
  node scripts/rnkit.mjs status
  node scripts/rnkit.mjs connections
  node scripts/rnkit.mjs logs --prefix <value> [options]
  node scripts/rnkit.mjs network --url <substring> [options]

Options:
  --prefix, --subprefix, --keyword, --exclude-keyword, --search, --type
  --url, --method, --header-name, --header-value
  --client-id, --start, --end, --limit, --full
`
}

function fail(message, exitCode = 2) {
  console.error(JSON.stringify({ status: "error", message }, null, 2))
  process.exitCode = exitCode
}

function parseArguments(argv) {
  const [command, ...tokens] = argv
  if (!command || command === "help" || command === "--help" || command === "-h") {
    return { help: true }
  }
  if (!COMMANDS.has(command)) throw new Error(`Unknown command: ${command}`)

  const options = {}
  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index]
    if (token === "--full") {
      options.full = true
      continue
    }
    if (!token.startsWith("--")) throw new Error(`Unexpected argument: ${token}`)
    const value = tokens[index + 1]
    if (!value || value.startsWith("--")) throw new Error(`Missing value for ${token}`)
    options[token.slice(2)] = value
    index += 1
  }
  return { command, options }
}

function append(params, options, flag, apiName = flag) {
  const value = options[flag]
  if (value != null && value !== "") params.set(apiName, value)
}

function buildQuery(options, kind) {
  const params = new URLSearchParams()
  append(params, options, "client-id", "clientId")
  append(params, options, "start")
  append(params, options, "end")
  append(params, options, "limit")

  if (kind === "logs") {
    append(params, options, "prefix")
    append(params, options, "subprefix")
    append(params, options, "keyword")
    append(params, options, "exclude-keyword", "excludeKeyword")
    append(params, options, "search")
    append(params, options, "type")
    if (!["prefix", "search", "type", "client-id", "start"].some((name) => options[name])) {
      throw new Error("logs requires at least one narrowing filter: --prefix, --search, --type, --client-id, or --start")
    }
  } else {
    if (!options.url) throw new Error("network requires --url")
    append(params, options, "url")
    append(params, options, "method")
    append(params, options, "header-name", "headerName")
    append(params, options, "header-value", "headerValue")
  }

  if (!params.has("limit")) params.set("limit", "20")
  return params
}

async function request(path, params) {
  const url = new URL(path, BASE_URL)
  if (params) url.search = params.toString()

  let response
  try {
    response = await fetch(url, { headers: { Accept: "application/json" }, signal: AbortSignal.timeout(5000) })
  } catch (error) {
    throw new Error(`ReactNativeKit is unavailable at ${BASE_URL}. Start the desktop app and retry. (${error.message})`)
  }

  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.error || `ReactNativeKit returned HTTP ${response.status}`)
  return body
}

function extractMessage(message) {
  if (typeof message === "string") return message
  if (Array.isArray(message)) return message.map(extractMessage).join(" ")
  if (message == null) return ""
  return JSON.stringify(message)
}

function prefixParts(message) {
  let remaining = message.trim()
  const brackets = []
  while (remaining.startsWith("[")) {
    const match = remaining.match(/^\[([^\]]+)\]\s*/)
    if (!match) break
    brackets.push(match[1])
    remaining = remaining.slice(match[0].length)
  }
  const words = remaining.split(/\s+/).filter(Boolean)
  return {
    prefix: brackets[0] ?? words[0] ?? null,
    subprefix: brackets[0] ? brackets[1] ?? words[0] ?? null : words[1] ?? null,
  }
}

function summarizeLogs(body, full) {
  const logs = body.logs || []
  if (full) return { status: "success", count: logs.length, events: logs }
  return {
    status: "success",
    count: logs.length,
    events: logs.map((entry) => {
      const message = extractMessage(entry.payload?.message) || entry.summary || ""
      const parts = prefixParts(message)
      return {
        messageId: entry.messageId,
        clientId: entry.clientId,
        date: entry.date,
        level: entry.payload?.level || "debug",
        prefix: parts.prefix,
        subprefix: parts.subprefix,
        message,
      }
    }),
  }
}

function summarizeNetwork(body, full) {
  const entries = body.entries || []
  if (full) return { status: "success", count: entries.length, entries }
  return {
    status: "success",
    count: entries.length,
    entries: entries.map((entry) => ({
      messageId: entry.messageId,
      clientId: entry.clientId,
      date: entry.date,
      duration: entry.duration,
      method: entry.request?.method || null,
      url: entry.request?.url || null,
      statusCode: entry.response?.status ?? null,
    })),
  }
}

async function main() {
  let parsed
  try {
    parsed = parseArguments(process.argv.slice(2))
  } catch (error) {
    fail(error.message)
    return
  }

  if (parsed.help) {
    console.log(usage())
    return
  }

  try {
    let result
    if (parsed.command === "status") result = await request("/status")
    if (parsed.command === "connections") result = await request("/connections")
    if (parsed.command === "logs") {
      result = summarizeLogs(await request("/logs", buildQuery(parsed.options, "logs")), parsed.options.full)
    }
    if (parsed.command === "network") {
      result = summarizeNetwork(await request("/network", buildQuery(parsed.options, "network")), parsed.options.full)
    }
    console.log(JSON.stringify(result, null, 2))
  } catch (error) {
    fail(error.message, 1)
  }
}

await main()
