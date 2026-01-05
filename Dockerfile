FROM postgis/postgis:18-3.6

ARG PGVECTOR_VERSION=v0.8.1

# Optional: APT mirror override (Debian-based image)
# Primary recommended approach is proxy env: http_proxy/https_proxy/no_proxy
# Escape hatch:
#   --build-arg APT_MIRROR=http://mirror.kambing.ui.ac.id/debian
ARG APT_MIRROR

LABEL org.opencontainers.image.title="PostgreSQL 18 + PostGIS + pgvector" \
      org.opencontainers.image.description="PostGIS base image (PostgreSQL 18) with pgvector installed. Auto-enable extensions (PostGIS + vector) with configurable runtime ensure." \
      org.opencontainers.image.source="https://github.com/sumeko/postgis-vector" \
      org.opencontainers.image.licenses="MIT"

RUN set -eux; \
  if [ -n "${APT_MIRROR:-}" ]; then \
    echo "[apt] Using explicit mirror: ${APT_MIRROR}"; \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}|g" /etc/apt/sources.list; \
  else \
    echo "[apt] Using default mirror: http://deb.debian.org/debian (proxy-aware if http_proxy is set)"; \
  fi; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    build-essential \
    postgresql-server-dev-18 \
  ; \
  rm -rf /var/lib/apt/lists/*

# Build & install pgvector
RUN set -eux; \
  git clone --branch "${PGVECTOR_VERSION}" --depth 1 https://github.com/pgvector/pgvector.git /tmp/pgvector; \
  cd /tmp/pgvector; \
  make; \
  make install; \
  rm -rf /tmp/pgvector

# initdb scripts (first-init only, standard postgres behavior)
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# runtime ensure (works even with existing volumes)
COPY scripts/ensure-extensions.sh /usr/local/bin/ensure-extensions.sh
COPY scripts/entrypoint-wrapper.sh /usr/local/bin/entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/ensure-extensions.sh /usr/local/bin/entrypoint-wrapper.sh \
  && chmod +x /docker-entrypoint-initdb.d/*.sh || true

# Defaults: auto-enable ON
ENV AUTO_ENABLE_EXTENSIONS="true" \
    AUTO_ENABLE_ON_START="true" \
    AUTO_ENABLE_POSTGIS="true" \
    AUTO_ENABLE_PGVECTOR="true" \
    AUTO_ENABLE_DB="__POSTGRES_DB__" \
    AUTO_ENABLE_SCHEMA="public" \
    AUTO_ENABLE_TIMEOUT_SECONDS="60"

ENTRYPOINT ["/usr/local/bin/entrypoint-wrapper.sh"]
CMD ["postgres"]
