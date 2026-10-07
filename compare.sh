#!/usr/bin/env bash
# Run the reproduction against several oxlint / oxlint-tsgolint pairs, each in a
# fresh temporary install, and print the lint result for each pair.
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/oxlint-tsgolint-compare.XXXXXX")"
trap 'rm -rf "$work"' EXIT

for pair in "1.85.0 7.0.2001" "1.85.0 7.0.2002" "1.85.0 7.0.2003" "1.87.0 7.0.2003"; do
  read -r oxlint tsgolint <<<"$pair"
  dir="$work/oxlint-$oxlint-tsgolint-$tsgolint"
  mkdir -p "$dir"
  cp -R "$root/src" "$root/.oxlintrc.json" "$root/tsconfig.json" "$root/.gitignore" "$dir/"
  echo '{ "name": "compare", "private": true }' > "$dir/package.json"
  if ! (cd "$dir" && npm install --silent --no-audit --no-fund --save-exact --legacy-peer-deps \
    "oxlint@$oxlint" "oxlint-tsgolint@$tsgolint" > install.log 2>&1); then
    echo "== oxlint $oxlint + oxlint-tsgolint $tsgolint: install failed"
    tail -5 "$dir/install.log"
    continue
  fi
  output="$(cd "$dir" && ./node_modules/.bin/oxlint --type-aware -f unix src 2>&1)"
  status=$?
  echo "== oxlint $oxlint + oxlint-tsgolint $tsgolint: exit $status"
  if [ -n "$output" ]; then
    printf '%s\n' "$output"
  fi
done
