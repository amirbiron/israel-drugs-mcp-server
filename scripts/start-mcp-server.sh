#!/usr/bin/env bash
# Launches this repo's MCP server over stdio, building it first when needed.
#
# dist/ is gitignored, so a fresh clone has nothing to run. The build happens
# here rather than in a SessionStart hook so that it is synchronous with server
# startup: the MCP client is waiting on this process, so the first connection
# cannot race an unfinished build.
#
# Everything before the final exec writes to stderr — stdout carries the
# JSON-RPC stream and must stay clean.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

DEPS_STAMP="node_modules/.israel-drugs-deps"
BUILD_STAMP="dist/.israel-drugs-build"

# Each stamp holds a content hash of the inputs its step consumes, and is
# written only after that step succeeds. An interrupted install or build
# therefore leaves no stamp and is retried on the next launch, and a deleted
# source file changes the hash just as an edited one does.
read_stamp() { cat "$1" 2>/dev/null; }

deps_want="$(sha256sum package.json | cut -d' ' -f1)"
if [ ! -d node_modules ] || [ "$deps_want" != "$(read_stamp "$DEPS_STAMP")" ]; then
  npm install --no-audit --no-fund >&2 || exit 1
  printf '%s\n' "$deps_want" >"$DEPS_STAMP"
fi

build_want="$(
  {
    sha256sum package.json tsconfig.json
    find src -type f -name '*.ts' -exec sha256sum {} + | sort
  } 2>/dev/null | sha256sum | cut -d' ' -f1
)"
if [ ! -f dist/index.js ] || [ "$build_want" != "$(read_stamp "$BUILD_STAMP")" ]; then
  npm run build >&2 || exit 1
  printf '%s\n' "$build_want" >"$BUILD_STAMP"
fi

exec node dist/index.js
