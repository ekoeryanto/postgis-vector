FROM postgres:18-bookworm

ARG PGVECTOR_VERSION=v0.8.1

# Optional: Debian APT mirror override (proxy env tetap recommended)
ARG APT_MIRROR

LABEL org.opencontainers.image.title="PostgreSQL 18 + PostGIS + pgvector" \
      org.opencontainers.image.description="PostgreSQL 18 (official) with PostGIS installed via APT and pgvector built from source. Auto-enable extensions with runtime ensure." \
      org.opencontainers.image.source="https://github.com/sumeko/postgis-vector" \
      org.opencontainers.image.licenses="MIT"

# --- APT + PostGIS + build deps ---
RUN set -eux; \
  if [ -n "${APT_MIRROR:-}" ]; then \
    echo "[apt] Using explicit mirror: ${APT_MIRROR}"; \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}|g" /etc/apt/sources.list; \
  else \
    echo "[apt] Using default mirror: http://deb.debian.org/debian (proxy-aware if http_proxy is set)"; \
  fi; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    # PostGIS for PostgreSQL 18 (from PGDG packages on official postgres image)
    postgresql-18-postgis-3 \
    postgresql-18-postgis-3-scripts \
    # optional CLI tools: shp2pgsql, raster2pgsql, pgsql2shp, etc.
    postgis \
    # for building pgvector
    postgresql-server-dev-18 \
  ; \
  rm -rf /var/lib/apt/lists/*

# --- Build & install pgvector ---
RUN set -eux; \
  git clone --branch "${PGVECTOR_VERSION}" --depth 1 https://github.com/pgvector/pgvector.git /tmp/pgvector; \
  cd /tmp/pgvector; \
  make; \
  make install; \
  rm -rf /tmp/pgvector

# --- initdb scripts (first init) ---
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# --- runtime ensure (works even with existing volumes) ---
COPY scripts/ensure-extensions.sh /usr/local/bin/ensure-extensions.sh
COPY scripts/entrypoint-wrapper.sh /usr/local/bin/entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/ensure-extensions.sh /usr/local/bin/entrypoint-wrapper.sh \
  && chmod +x /docker-entrypoint-initdb.d/*.sh || true

# Default: auto-enable ON
ENV AUTO_ENABLE_EXTENSIONS="true" \
    AUTO_ENABLE_ON_START="true" \
    AUTO_ENABLE_POSTGIS="true" \
    AUTO_ENABLE_PGVECTOR="true" \
    AUTO_ENABLE_DB="__POSTGRES_DB__" \
    AUTO_ENABLE_SCHEMA="public" \
    AUTO_ENABLE_TIMEOUT_SECONDS="60"

ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
CMD ["postgres"]
