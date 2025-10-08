FROM alpine:latest

# Installer les dépendances nécessaires
RUN apk add --no-cache wget tar ca-certificates

# Définir les arguments pour la version et l'architecture
ARG VERSION=v0.5.2
ARG ARCH=amd64
ARG TARGET_NAME=pubky-core-${VERSION}-linux-${ARCH}

# Télécharger, extraire, renommer et nettoyer
RUN wget https://github.com/pubky/pubky-core/releases/download/${VERSION}/${TARGET_NAME}.tar.gz && \
    tar -xzf ${TARGET_NAME}.tar.gz && \
    mv ${TARGET_NAME}/pubky-homeserver /usr/local/bin/homeserver && \
    chmod +x /usr/local/bin/homeserver && \
    rm ${TARGET_NAME}.tar.gz && \
    rm -r ${TARGET_NAME}

# Le point d'entrée est défini dans le docker-compose.yml
