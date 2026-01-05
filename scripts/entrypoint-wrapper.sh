#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_ENTRYPOINT="/usr/local/bin/docker-entrypoint.sh"

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

AUTO_ENABLE_EXTENSIONS="${AUTO_ENABLE_EXTENSIONS:-true}"
AUTO_ENABLE_ON_START="${AUTO_ENABLE_ON_START:-true}"
AUTO_ENABLE_TIMEOUT_SECONDS="${AUTO_ENABLE_TIMEOUT_SECONDS:-60}"

# Non-postgres commands behave like original image
if [[ "${1:-}" != "postgres" && "${1:-}" != "docker-entrypoint.sh" ]]; then
  exec "$ORIGINAL_ENTRYPOINT" "$@"
fi

# Start postgres via original entrypoint as background child
set +e
"$ORIGINAL_ENTRYPOINT" "$@" &
child_pid=$!
set -e

term_handler() {
  echo "[wrapper] Caught signal, forwarding to postgres (pid=$child_pid)"
  kill -TERM "$child_pid" 2>/dev/null || true
}
trap term_handler TERM INT

if is_true "$AUTO_ENABLE_EXTENSIONS" && is_true "$AUTO_ENABLE_ON_START"; then
  echo "[wrapper] AUTO_ENABLE_ON_START=true -> waiting for postgres readiness (timeout=${AUTO_ENABLE_TIMEOUT_SECONDS}s)"

  export PGPASSWORD="${POSTGRES_PASSWORD:-}"
  export PGHOST=127.0.0.1
  export PGPORT=5432

  deadline=$(( $(date +%s) + AUTO_ENABLE_TIMEOUT_SECONDS ))
  while true; do
    if pg_isready -h 127.0.0.1 -p 5432 -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
      break
    fi
    if [[ $(date +%s) -ge $deadline ]]; then
      echo "[wrapper] Timeout waiting for postgres readiness; skip ensure-extensions"
      break
    fi
    sleep 1
  done

  if pg_isready -h 127.0.0.1 -p 5432 -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
    echo "[wrapper] Postgres is ready, ensuring extensions..."
    /usr/local/bin/ensure-extensions.sh || echo "[wrapper] ensure-extensions failed (continuing)"
  fi
else
  echo "[wrapper] Runtime ensure disabled (AUTO_ENABLE_ON_START=false or AUTO_ENABLE_EXTENSIONS=false)"
fi

wait "$child_pid"
