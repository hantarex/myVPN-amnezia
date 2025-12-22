# ============================================================================
# STAGE 1: Сборка Node.js приложения
# ============================================================================
FROM node:18-alpine AS builder

WORKDIR /build

# Копирование package files для кеширования слоев
COPY src/package*.json ./

# Установка production зависимостей
RUN npm ci --omit=dev --ignore-scripts && \
    npm cache clean --force

# Копирование исходного кода
COPY src/ ./

# ============================================================================
# STAGE 2: Сборка AmneziaWG
# ============================================================================
FROM alpine:3.20 AS amneziawg-builder

# Установка зависимостей для сборки
RUN apk add --no-cache \
    git \
    build-base \
    linux-headers \
    libmnl-dev

# Клонирование и сборка amneziawg-tools
WORKDIR /build
RUN git clone https://github.com/amnezia-vpn/amneziawg-tools.git && \
    cd amneziawg-tools/src && \
    make && \
    make install DESTDIR=/build/output

# ============================================================================
# STAGE 3: Финальный runtime образ
# ============================================================================
FROM alpine:3.20

# Метаданные образа
LABEL maintainer="AmnesiaWG VPN Project"
LABEL description="AmneziaWG VPN Server with Web UI"
LABEL version="1.0.0"

# Установка runtime зависимостей
RUN apk add --no-cache \
    # Основные утилиты
    bash \
    ca-certificates \
    dumb-init \
    tzdata \
    # Сетевые инструменты
    iptables \
    iptables-legacy \
    ip6tables \
    iproute2 \
    wireguard-tools \
    # Node.js runtime
    nodejs \
    npm \
    # Дополнительные утилиты
    curl \
    openresolv \
    && \
    # Настройка iptables-nft как основного
    ln -sf /sbin/xtables-nft-multi /sbin/iptables && \
    ln -sf /sbin/xtables-nft-multi /sbin/ip6tables && \
    # Создание необходимых директорий
    mkdir -p /app /etc/wireguard /var/lib/wireguard /var/run/wireguard && \
    # Очистка кеша
    rm -rf /var/cache/apk/*

# Копирование AmneziaWG tools из builder stage
COPY --from=amneziawg-builder /build/output/usr/bin/* /usr/bin/

# Замена wg на awg и wg-quick на awg-quick через символические ссылки
# Это необходимо, т.к. приложение вызывает команды 'wg' и 'wg-quick', но они должны использовать
# 'awg' и 'awg-quick' (AmneziaWG), которые понимают параметры обфускации (Jc, Jmin, Jmax, etc)
RUN if [ ! -f /usr/bin/awg-quick ]; then \
        sed 's/type wireguard/type amneziawg/g' /usr/bin/wg-quick > /usr/bin/awg-quick && \
        chmod +x /usr/bin/awg-quick; \
    fi && \
    rm -f /usr/bin/wg /usr/bin/wg-quick && \
    ln -s /usr/bin/awg /usr/bin/wg && \
    ln -s /usr/bin/awg /usr/local/bin/wg && \
    ln -s /usr/bin/awg-quick /usr/bin/wg-quick && \
    ln -s /usr/bin/awg-quick /usr/local/bin/wg-quick

# Копирование Node.js приложения из builder stage
COPY --from=builder /build/node_modules /app/node_modules
COPY --from=builder /build /app

# Копирование вспомогательных скриптов
COPY build/wgpw.sh /usr/local/bin/wgpw
COPY build/entrypoint.sh /usr/local/bin/entrypoint.sh

# Установка прав на выполнение
RUN chmod +x /usr/local/bin/wgpw && \
    chmod +x /usr/local/bin/entrypoint.sh

# Переменные окружения по умолчанию
ENV LANG=ru \
    DEBUG=Server,WireGuard \
    WG_HOST= \
    WG_PORT=51820 \
    WG_DEVICE=eth0 \
    WG_MTU= \
    WG_PERSISTENT_KEEPALIVE=25 \
    WG_DEFAULT_ADDRESS=10.8.0.x \
    WG_DEFAULT_DNS=1.1.1.1 \
    WG_ALLOWED_IPS=0.0.0.0/0,::/0 \
    PORT=51821 \
    WEBUI_HOST=0.0.0.0 \
    UI_TRAFFIC_STATS=false \
    ENABLE_PROMETHEUS_METRICS=false

# Рабочая директория
WORKDIR /app

# Healthcheck для проверки работоспособности
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:${PORT:-51821}/api/health || exit 1

# Открытые порты
EXPOSE 51820/udp 51821/tcp

# Entrypoint с dumb-init для правильной обработки сигналов
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Команда запуска
CMD ["/usr/local/bin/entrypoint.sh"]
