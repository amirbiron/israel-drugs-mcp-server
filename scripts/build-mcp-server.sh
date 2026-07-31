#!/usr/bin/env bash
# Builds this repo's MCP server so the `node dist/index.js` entrypoint declared
# in .mcp.json exists.
#
# `dist/` is gitignored, so a fresh clone (Claude Code cloud sessions, CI, a new
# checkout) has no build output and the israel-drugs MCP server cannot start.
#
# Runs from a SessionStart hook, so it must never fail the session: every step
# falls through to `exit 0`.

set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-"$(dirname "$0")/.."}" || exit 0

# Nothing to do when dist/ is present and no source file is newer than it.
if [ -f dist/index.js ] && [ -z "$(find src -name '*.ts' -newer dist/index.js -print -quit)" ]; then
  exit 0
fi

if [ ! -d node_modules ]; then
  npm install --no-audit --no-fund || exit 0
fi

npm run build || exit 0
exit 0
