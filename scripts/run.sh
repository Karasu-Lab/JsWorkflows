#!/usr/bin/env bash
set -euo pipefail

task="${1:?usage: run.sh <format|typecheck|build>}"
tools="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v pnpm > /dev/null; then
    npm install --global pnpm
fi

pnpm install --dir "$tools" --frozen-lockfile --ignore-scripts

if [ -f pnpm-lock.yaml ]; then
    pnpm install --frozen-lockfile
else
    pnpm install
fi

case "$task" in
    format)
        "$tools/node_modules/.bin/prettier" \
            --config "$tools/.prettierrc.json" \
            --ignore-unknown \
            --write "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs,json,css}"

        if ! git diff --quiet; then
            git config user.name "github-actions[bot]"
            git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
            git commit --all --message "style: apply prettier formatting"
            git push
        fi
        ;;
    typecheck)
        "$tools/node_modules/.bin/eslint" \
            --config "$tools/eslint.config.mjs" \
            --no-error-on-unmatched-pattern \
            .

        if [ -f tsconfig.json ]; then
            pnpm exec tsc --noEmit
        fi
        ;;
    build)
        if node -e 'process.exit(require("./package.json").scripts?.build ? 0 : 1)'; then
            pnpm run build
        fi
        ;;
    *)
        echo "unknown task: $task" >&2
        exit 1
        ;;
esac
