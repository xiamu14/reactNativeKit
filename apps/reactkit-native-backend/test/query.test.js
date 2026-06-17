const assert = require("node:assert/strict")
const test = require("node:test")

const { queryLogs, queryNetwork } = require("../src/query")

function params(values) {
  return new URLSearchParams(values)
}

const commands = [
  {
    messageId: 1,
    clientId: "ios-1",
    type: "log",
    date: "2026-06-17T08:00:00.000Z",
    summary: "[Sync] start loading",
    details: "[Sync] start loading",
    payload: { level: "debug", message: "[Sync] start loading" },
  },
  {
    messageId: 2,
    clientId: "ios-1",
    type: "log",
    date: "2026-06-17T08:01:00.000Z",
    summary: "[Sync] complete success",
    details: "[Sync] complete success",
    payload: { level: "info", message: "[Sync] complete success" },
  },
  {
    messageId: 3,
    clientId: "ios-1",
    type: "api.response",
    date: "2026-06-17T08:02:00.000Z",
    payload: {
      duration: 42,
      request: { method: "GET", url: "https://example.com/api/items", headers: { Authorization: "Bearer abc" } },
      response: { status: 200, body: { ok: true }, headers: { "x-request-id": "req-1" } },
    },
  },
]

test("queryLogs filters prefix, subprefix, keyword, exclusion, and time", () => {
  const result = queryLogs(commands, params({
    prefix: "Sync",
    subprefix: "complete",
    keyword: "success",
    excludeKeyword: "failed",
    start: "2026-06-17T08:00:30.000Z",
    limit: "5",
  }))

  assert.equal(result.length, 1)
  assert.equal(result[0].messageId, 2)
})

test("queryLogs keeps the existing general search behavior", () => {
  const result = queryLogs(commands, params({ search: "loading", limit: "5" }))
  assert.deepEqual(result.map((entry) => entry.messageId), [1])
})

test("queryNetwork filters URL, method, and headers", () => {
  const result = queryNetwork(commands, params({
    url: "/api/items",
    method: "get",
    headerName: "authorization",
    headerValue: "abc",
  }))

  assert.equal(result.length, 1)
  assert.equal(result[0].response.status, 200)
})

test("queryNetwork requires a URL filter", () => {
  assert.throws(() => queryNetwork(commands, params({})), /url is required/)
})
