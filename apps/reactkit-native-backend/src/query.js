const MAX_QUERY_RESULTS = 500

class QueryValidationError extends Error {
  constructor(message) {
    super(message)
    this.name = "QueryValidationError"
    this.statusCode = 400
  }
}

function extractMessageText(message) {
  if (typeof message === "string") return message
  if (Array.isArray(message)) return message.map(extractMessageText).join(" ")
  if (message == null) return ""
  try {
    return JSON.stringify(message)
  } catch {
    return String(message)
  }
}

function extractPrefixParts(message) {
  let remaining = message.trim()
  const bracketTokens = []

  while (remaining.startsWith("[")) {
    const match = remaining.match(/^\[([^\]]+)\]\s*/)
    if (!match) break
    bracketTokens.push(match[1])
    remaining = remaining.slice(match[0].length)
  }

  const words = remaining.trim().split(/\s+/).filter(Boolean)
  return {
    prefix: bracketTokens[0] ?? words[0] ?? null,
    subprefix: bracketTokens[0] ? bracketTokens[1] ?? words[0] ?? null : words[1] ?? null,
  }
}

function normalizeToken(value) {
  return String(value || "").trim().replace(/^\[|\]$/g, "").toLowerCase()
}

function parseLimit(raw, fallback = 20) {
  if (raw == null || raw === "") return fallback
  const value = Number.parseInt(raw, 10)
  if (!Number.isInteger(value) || value < 1) {
    throw new QueryValidationError(`Invalid limit: ${raw}`)
  }
  return Math.min(value, MAX_QUERY_RESULTS)
}

function parseTimestamp(raw, name) {
  if (!raw) return null
  const value = Date.parse(raw)
  if (Number.isNaN(value)) throw new QueryValidationError(`Invalid ${name}: ${raw}`)
  return value
}

function timeRange(searchParams) {
  return {
    start: parseTimestamp(searchParams.get("start"), "start"),
    end: parseTimestamp(searchParams.get("end"), "end"),
  }
}

function withinRange(command, range) {
  const timestamp = Date.parse(command.date || "")
  if (range.start != null && timestamp < range.start) return false
  if (range.end != null && timestamp > range.end) return false
  return true
}

function queryLogs(commands, searchParams) {
  const clientId = searchParams.get("clientId")
  const type = searchParams.get("type")
  const search = normalizeToken(searchParams.get("search"))
  const prefix = searchParams.get("prefix")
  const subprefix = searchParams.get("subprefix")
  const keyword = normalizeToken(searchParams.get("keyword"))
  const excludeKeyword = normalizeToken(searchParams.get("excludeKeyword"))
  const limit = parseLimit(searchParams.get("limit"), 200)
  const range = timeRange(searchParams)

  if (subprefix && !prefix) {
    throw new QueryValidationError("subprefix requires prefix")
  }

  const matches = []
  for (const command of [...commands].reverse()) {
    if (clientId && command.clientId !== clientId) continue
    if (type && command.type !== type) continue
    if (!withinRange(command, range)) continue

    const message = extractMessageText(command.payload?.message)
    if (prefix || subprefix || keyword || excludeKeyword) {
      if (command.type !== "log") continue
      const parts = extractPrefixParts(message)
      if (prefix && normalizeToken(parts.prefix) !== normalizeToken(prefix)) continue
      if (subprefix && normalizeToken(parts.subprefix) !== normalizeToken(subprefix)) continue
      const normalizedMessage = message.toLowerCase()
      if (keyword && !normalizedMessage.includes(keyword)) continue
      if (excludeKeyword && normalizedMessage.includes(excludeKeyword)) continue
    }

    if (search) {
      const haystack = [command.type, command.summary, command.details, command.payload]
        .map((value) => {
          try {
            return typeof value === "string" ? value : JSON.stringify(value)
          } catch {
            return String(value || "")
          }
        })
        .join(" ")
        .toLowerCase()
      if (!haystack.includes(search)) continue
    }

    matches.push(command)
    if (matches.length >= limit) break
  }
  return matches
}

function queryNetwork(commands, searchParams) {
  const urlFilter = searchParams.get("url")?.trim()
  if (!urlFilter) throw new QueryValidationError("url is required")

  const clientId = searchParams.get("clientId")
  const method = normalizeToken(searchParams.get("method"))
  const headerName = normalizeToken(searchParams.get("headerName"))
  const headerValue = normalizeToken(searchParams.get("headerValue"))
  const limit = parseLimit(searchParams.get("limit"), 20)
  const range = timeRange(searchParams)
  const normalizedUrl = urlFilter.toLowerCase()
  const matches = []

  for (const command of [...commands].reverse()) {
    if (command.type !== "api.response") continue
    if (clientId && command.clientId !== clientId) continue
    if (!withinRange(command, range)) continue

    const request = command.payload?.request || {}
    const response = command.payload?.response || {}
    if (!String(request.url || "").toLowerCase().includes(normalizedUrl)) continue
    if (method && normalizeToken(request.method) !== method) continue

    if (headerName) {
      const headers = [...Object.entries(request.headers || {}), ...Object.entries(response.headers || {})]
      const found = headers.some(([name, value]) => {
        if (normalizeToken(name) !== headerName) return false
        return !headerValue || String(value).toLowerCase().includes(headerValue)
      })
      if (!found) continue
    }

    matches.push({
      messageId: command.messageId,
      clientId: command.clientId,
      date: command.date,
      duration: command.payload?.duration,
      request,
      response,
    })
    if (matches.length >= limit) break
  }
  return matches
}

module.exports = {
  QueryValidationError,
  extractPrefixParts,
  queryLogs,
  queryNetwork,
}
