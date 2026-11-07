# syntax=docker/dockerfile:1
# Only these two public values are read during the build. Render injects the
# database, Clerk secret and storage credentials at runtime only.
FROM node:22-bookworm-slim AS web-config
WORKDIR /app
COPY scripts/web-config.mjs ./scripts/web-config.mjs
ARG CLERK_PUBLISHABLE_KEY
ARG WEB_API_BASE_URL
RUN node scripts/web-config.mjs

FROM debian:bookworm-slim AS flutter-builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git unzip xz-utils libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
# Match the project's Dart ^3.13.3 requirement; verify the release commit.
RUN git clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git /opt/flutter \
    && test "$(git -C /opt/flutter rev-parse HEAD)" = "9584c6713b324636289d067944a46fd6b49df14b"
ENV PATH="/opt/flutter/bin:${PATH}" CI=true
RUN flutter config --no-analytics --enable-web && flutter precache --web
WORKDIR /app
COPY pubspec.yaml pubspec.lock analysis_options.yaml l10n.yaml ./
COPY assets/ ./assets/
COPY lib/ ./lib/
COPY web/ ./web/
COPY --from=web-config /app/.local/web-config.json ./.local/web-config.json
RUN flutter pub get --enforce-lockfile \
    && flutter build web --release --no-web-resources-cdn \
       --dart-define-from-file=.local/web-config.json

FROM node:22-bookworm-slim AS runtime
ENV NODE_ENV=production SERVE_FLUTTER_WEB=true PORT=10000
WORKDIR /app/backend
COPY --chown=node:node backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force
COPY --chown=node:node backend/src/ ./src/
COPY --chown=node:node backend/server.js backend/notification-worker.js ./
COPY --from=flutter-builder --chown=node:node /app/build/web /app/build/web
USER node
EXPOSE 10000
CMD ["node", "server.js"]
