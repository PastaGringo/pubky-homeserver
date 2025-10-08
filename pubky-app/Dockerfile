# Fast & simple build for pubky-app (Next.js)
# Single-stage for simplicity and speed
FROM node:22.9.0-slim

# Working directory
WORKDIR /usr/src/app

# System deps (git + certs) for cloning
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Build-time configuration
ARG PUBKY_APP_BRANCH=master
ARG NEXT_PUBLIC_HOMESERVER
ARG NEXT_PUBLIC_NEXUS
ARG NEXT_PUBLIC_TESTNET=false
ARG NEXT_PUBLIC_DEFAULT_HTTP_RELAY
ARG NEXT_PUBLIC_PKARR_RELAYS
ARG NEXT_PUBLIC_MODERATION_ID
ARG NEXT_PUBLIC_MODERATED_TAGS
ARG NEXT_ENABLE_PLAUSIBLE=false

# Make NEXT_PUBLIC_* available at build time
ENV NEXT_PUBLIC_HOMESERVER=${NEXT_PUBLIC_HOMESERVER} \
    NEXT_PUBLIC_NEXUS=${NEXT_PUBLIC_NEXUS} \
    NEXT_PUBLIC_TESTNET=${NEXT_PUBLIC_TESTNET} \
    NEXT_PUBLIC_DEFAULT_HTTP_RELAY=${NEXT_PUBLIC_DEFAULT_HTTP_RELAY} \
    NEXT_PUBLIC_PKARR_RELAYS=${NEXT_PUBLIC_PKARR_RELAYS} \
    NEXT_PUBLIC_MODERATION_ID=${NEXT_PUBLIC_MODERATION_ID} \
    NEXT_PUBLIC_MODERATED_TAGS=${NEXT_PUBLIC_MODERATED_TAGS} \
    NEXT_ENABLE_PLAUSIBLE=${NEXT_ENABLE_PLAUSIBLE}

# Shallow clone the desired branch (fast)
RUN echo "[pubky-app build] Cloning branch: ${PUBKY_APP_BRANCH}" && \
    git clone --depth 1 --branch "${PUBKY_APP_BRANCH}" https://github.com/pubky/pubky-app.git . && \
    echo "[pubky-app build] Using commit $(git rev-parse --short HEAD)"

# Install dependencies (use npm ci when lockfile is present)
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Build Next.js app
RUN npm run build

# Expose default port
EXPOSE 4200

# Run the app
CMD ["npm", "run", "serve:prod"]