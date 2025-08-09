#!/usr/bin/env bash
set -euo pipefail

echo "Running generate_openring.sh"
echo "PATH: $PATH"
echo "which openring: $(which openring || echo 'not found')"
echo "which openring-rs: $(which openring-rs || echo 'not found')"


# Paths
FEEDLIST="config/openring/feeds.txt"
TEMPLATE="config/openring/in.html"
OUT="static/openring.html"


# Pick binary
if command -v openring >/dev/null 2>&1; then
  BIN="openring"
elif command -v openring-rs >/dev/null 2>&1; then
  BIN="openring-rs"
else
  echo "Error: neither 'openring' nor 'openring-rs' found in PATH."
  exit 2
fi

# Build args from the feedlist
ARGS=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"         # strip comments
  line="${line#"${line%%[![:space:]]*}"}"  # trim leading spaces
  line="${line%"${line##*[![:space:]]}"}"  # trim trailing spaces
  [ -z "$line" ] && continue
  ARGS+=("-s" "$line")
done < "$FEEDLIST"

# Limit to 4 articles
ARGS+=("-n" "8")

# Run
if [ "$BIN" = "openring-rs" ]; then
  mkdir -p .openring-cache
  openring-rs --cache --cache-dir ./.openring-cache --template-file "$TEMPLATE" "${ARGS[@]}" > "$OUT"
else
  openring "${ARGS[@]}" < "$TEMPLATE" > "$OUT"
fi

echo "Wrote $OUT"
