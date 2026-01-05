#!/usr/bin/env bash
set -euo pipefail

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|y|Y|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

AUTO_ENABLE_EXTENSIONS="${AUTO_ENABLE_EXTENSIONS:-true}"
AUTO_ENABLE_POSTGIS="${AUTO_ENABLE_POSTGIS:-true}"
AUTO_ENABLE_PGVECTOR="${AUTO_ENABLE_PGVECTOR:-true}"
AUTO_ENABLE_DB="${AUTO_ENABLE_DB:-__POSTGRES_DB__}"
AUTO_ENABLE_SCHEMA="${AUTO_ENABLE_SCHEMA:-public}"

if ! is_true "$AUTO_ENABLE_EXTENSIONS"; then
  echo "[initdb] AUTO_ENABLE_EXTENSIONS=false -> skip"
  exit 0
fi

resolve_default_db() {
  echo "${POSTGRES_DB:-postgres}"
}

resolve_db_list() {
  if [[ "$AUTO_ENABLE_DB" == "__POSTGRES_DB__" ]]; then
    resolve_default_db
    return 0
  fi

  if [[ "$AUTO_ENABLE_DB" == "__ALL__" ]]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" -Atc \
      "SELECT datname FROM pg_database WHERE datistemplate = false;"
    return 0
  fi

  echo "${AUTO_ENABLE_DB//,/ }"
}

DB_LIST="$(resolve_db_list)"

SQL=""
SQL+="CREATE SCHEMA IF NOT EXISTS \"${AUTO_ENABLE_SCHEMA}\";\n"

if is_true "$AUTO_ENABLE_POSTGIS"; then
  SQL+="CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA \"${AUTO_ENABLE_SCHEMA}\";\n"
fi

if is_true "$AUTO_ENABLE_PGVECTOR"; then
  SQL+="CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA \"${AUTO_ENABLE_SCHEMA}\";\n"
fi

for db in $DB_LIST; do
  echo "[initdb] Creating extensions on db='${db}', schema='${AUTO_ENABLE_SCHEMA}' (postgis=${AUTO_ENABLE_POSTGIS}, vector=${AUTO_ENABLE_PGVECTOR})"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<-EOSQL
$(echo -e "$SQL")
EOSQL
done
