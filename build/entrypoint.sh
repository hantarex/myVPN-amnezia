#!/bin/bash
# AmnesiaWG VPN Server Entrypoint
# Настройка окружения и запуск приложения

set -e

echo "=========================================="
echo "AmnesiaWG VPN Server Starting..."
echo "=========================================="

# Проверка обязательных переменных
if [ -z "$WG_HOST" ]; then
    echo "ERROR: WG_HOST environment variable is required"
    echo "Please set the public IP or domain name of your VPN server"
    exit 1
fi

if [ -z "$PASSWORD_HASH" ]; then
    echo "ERROR: PASSWORD_HASH environment variable is required"
    echo "Generate with: docker run --rm <image> wgpw 'your_password'"
    exit 1
fi

# Загрузка модуля WireGuard (если не загружен)
if ! lsmod | grep -q wireguard; then
    echo "Loading WireGuard kernel module..."
    modprobe wireguard 2>/dev/null || echo "Warning: Could not load wireguard module (may be built-in)"
fi

# Настройка iptables
echo "Configuring firewall rules..."

# Включение IP forwarding
sysctl -w net.ipv4.ip_forward=1 > /dev/null
sysctl -w net.ipv4.conf.all.src_valid_mark=1 > /dev/null

# Очистка существующих правил (игнорируем ошибки)
iptables -t nat -F POSTROUTING 2>/dev/null || true
iptables -F FORWARD 2>/dev/null || true

# Настройка NAT для VPN
echo "Setting up NAT for device: ${WG_DEVICE}"
iptables -t nat -A POSTROUTING -o ${WG_DEVICE} -j MASQUERADE
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT

echo "Firewall rules configured successfully"

# Создание директорий
mkdir -p /var/run/wireguard
mkdir -p /etc/wireguard

# Установка прав доступа
chmod 700 /etc/wireguard
chmod 700 /var/run/wireguard

# Информация о версиях
echo "=========================================="
echo "Environment Information:"
echo "Alpine version: $(cat /etc/alpine-release)"
echo "Node.js version: $(node --version)"
echo "iptables version: $(iptables --version | head -n1)"
echo "WireGuard: $(wg --version 2>&1 | head -n1)"
if command -v awg &> /dev/null; then
    echo "AmneziaWG: $(awg --version 2>&1 | head -n1 || echo 'installed')"
fi
echo "=========================================="
echo "Configuration:"
echo "WG_HOST: ${WG_HOST}"
echo "WG_PORT: ${WG_PORT}"
echo "WG_DEVICE: ${WG_DEVICE}"
echo "WG_DEFAULT_DNS: ${WG_DEFAULT_DNS}"
echo "WEB UI PORT: ${PORT}"
echo "=========================================="

# Запуск Node.js приложения
echo "Starting application..."
exec node /app/server.js
