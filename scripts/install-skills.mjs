#!/usr/bin/env bun
import { cp, mkdir, readdir, rm } from "node:fs/promises"
import { homedir } from "node:os"
import { basename, join, resolve } from "node:path"
import { cancel, isCancel, multiselect, outro } from "@clack/prompts"

const root = resolve(new URL("..", import.meta.url).pathname)
const sourceRoot = join(root, "skills")
const targets = {
  claude: { label: "Claude Code", dir: join(homedir(), ".claude", "skills") },
  codex: { label: "Codex", dir: join(homedir(), ".codex", "skills") },
  opencode: { label: "opencode", dir: join(process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "opencode", "skills") },
  global: { label: "Global", dir: join(homedir(), ".agents", "skills") },
}
const promptTargets = Object.entries(targets).filter(([name]) => name !== "global")

const cliTargets = process.argv.slice(2).map((arg) => arg.replace(/^--/, ""))
let selected = cliTargets.filter((name) => name in targets)

if (!selected.length && process.stdin.isTTY) {
  const picked = await multiselect({
    message: "Install/update rnkit skill to (select none for Global):",
    required: false,
    options: promptTargets.map(([value, target]) => ({
      value,
      label: target.label,
    })),
  })

  if (isCancel(picked)) {
    cancel("Cancelled")
    process.exit(0)
  }

  selected = picked.length ? picked : ["global"]
}

if (!selected.length) selected = ["global"]

const skills = (await readdir(sourceRoot, { withFileTypes: true })).filter((entry) => entry.isDirectory())

for (const targetName of selected) {
  const target = targets[targetName]
  await mkdir(target.dir, { recursive: true })

  for (const skill of skills) {
    const from = join(sourceRoot, skill.name)
    const to = join(target.dir, basename(skill.name))
    await rm(to, { recursive: true, force: true })
    await cp(from, to, { recursive: true })
  }
}

outro("Skills installed")
