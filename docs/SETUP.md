# Детальная инструкция по настройке AmnesiaWG VPN

## Подготовка сервера

### 1. Требования к серверу

- **OS**: Ubuntu 20.04+, Debian 11+, CentOS 8+
- **CPU**: 1 ядро (рекомендуется 2+)
- **RAM**: 512 MB (рекомендуется 1 GB+)
- **Disk**: 5 GB свободного места
- **Network**: Публичный IP адрес

### 2. Обновление системы

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 3. Установка Docker и Docker Compose

```bash
# Установка Docker
curl -sSL https://get.docker.com | sh

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Выйдите и войдите снова для применения изменений
```

### 4. Настройка firewall

#### UFW (Ubuntu/Debian)
```bash
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw allow 51821/tcp
sudo ufw enable
sudo ufw status
```

#### firewalld (CentOS/RHEL)
```bash
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --add-port=51821/tcp
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

## Установка и настройка

### Шаг 1: Подготовка конфигурации

```bash
# Создать .env файл из шаблона
cp .env.example .env
```

### Шаг 2: Генерация хеша пароля

```bash
# Используя Docker образ amnezia-wg-easy
docker run --rm ghcr.io/w0rng/amnezia-wg-easy wgpw 'мой_супер_секретный_пароль'

# ИЛИ используя htpasswd (если установлен)
htpasswd -nbB admin 'мой_супер_секретный_пароль' | cut -d ':' -f 2
```

Скопируйте полученный хеш - он понадобится на следующем шаге.

### Шаг 3: Определение сетевых параметров

```bash
# Узнать публичный IP адрес
curl -4 ifconfig.me

# Узнать сетевой интерфейс (обычно eth0, ens3, или enp0s3)
ip route | grep default | awk '{print $5}'

# Альтернативный способ
ip addr show | grep 'state UP' | awk '{print $2}' | cut -d ':' -f 1
```

### Шаг 4: Редактирование .env файла

```bash
nano .env
```

Обязательно заполните следующие параметры:

```bash
# Хеш пароля из шага 2
PASSWORD_HASH=ВАШ_ХЕШ_ПАРОЛЯ

# Публичный IP из шага 3
WG_HOST=203.0.113.1

# Сетевой интерфейс из шага 3 (обычно eth0)
WG_DEVICE=eth0
```

### Шаг 5: Запуск VPN сервера

```bash
# Запустить контейнер в фоновом режиме
docker compose up -d

# Проверить логи
docker compose logs -f

# Проверить статус
docker compose ps
```

### Шаг 6: Проверка работы

```bash
# Проверить доступность Web UI
curl http://localhost:51821

# Проверить WireGuard интерфейс
docker compose exec amnezia-wg-easy wg show

# Проверить сетевые настройки
docker compose exec amnezia-wg-easy ip addr show wg0
```

## Настройка клиентов

### Android

1. Установите **Amnezia VPN** из Google Play Store
2. В Web UI создайте нового клиента
3. Отсканируйте QR-код в приложении
4. Нажмите "Подключиться"

**Альтернатива**: Используйте стандартный WireGuard клиент

### iOS

1. Установите **WireGuard** из App Store
2. В Web UI создайте нового клиента
3. Нажмите "Добавить туннель" → "Создать из QR-кода"
4. Отсканируйте QR-код
5. Активируйте туннель

### Windows

1. Скачайте WireGuard с [wireguard.com](https://www.wireguard.com/install/)
2. Установите приложение
3. В Web UI скачайте конфигурацию клиента (файл .conf)
4. В WireGuard: "Добавить туннель" → "Импортировать из файла"
5. Выберите скачанный файл
6. Активируйте туннель

### Linux

```bash
# Установить WireGuard
sudo apt install wireguard  # Ubuntu/Debian
sudo yum install wireguard-tools  # CentOS/RHEL

# Скачать конфигурацию из Web UI
# Сохранить как /etc/wireguard/wg0.conf

# Запустить туннель
sudo wg-quick up wg0

# Остановить туннель
sudo wg-quick down wg0

# Автозапуск при загрузке системы
sudo systemctl enable wg-quick@wg0
```

### macOS

1. Установите WireGuard из App Store
2. Следуйте инструкциям для iOS

## Продвинутая конфигурация

### Split Tunnel (частичный VPN)

Если вы хотите направлять через VPN только определенный трафик:

```bash
# В .env измените:
WG_ALLOWED_IPS=10.8.0.0/24

# Это направит через VPN только трафик к другим клиентам
# Интернет-трафик будет идти напрямую
```

### Full Tunnel (весь трафик через VPN)

```bash
# В .env (настройка по умолчанию):
WG_ALLOWED_IPS=0.0.0.0/0, ::/0

# Весь трафик (IPv4 и IPv6) будет идти через VPN
```

### Использование своего DNS сервера

```bash
# Для использования DNS сервера вашей сети
WG_DEFAULT_DNS=192.168.1.1

# Для использования нескольких DNS серверов
WG_DEFAULT_DNS=1.1.1.1, 8.8.8.8

# Для отключения DNS (клиенты будут использовать свой)
WG_DEFAULT_DNS=
```

### Изменение MTU для медленных сетей

```bash
# Для мобильных сетей или нестабильного соединения
WG_MTU=1280

# Для большинства сетей (по умолчанию)
WG_MTU=1420

# Для высокоскоростных сетей
WG_MTU=1500
```

### Отключение keepalive

```bash
# Для экономии трафика (но могут быть проблемы с NAT)
WG_PERSISTENT_KEEPALIVE=0

# Для стабильной работы за NAT (рекомендуется)
WG_PERSISTENT_KEEPALIVE=25
```

## Мониторинг

### Включение статистики трафика

```bash
# В .env:
UI_TRAFFIC_STATS=true

# Перезапустить контейнер
docker compose restart
```

### Prometheus метрики

```bash
# В .env:
ENABLE_PROMETHEUS_METRICS=true

# Метрики будут доступны на:
# http://ВАШ_IP:51821/metrics
```

### Просмотр подключенных клиентов

```bash
# Список активных подключений
docker compose exec amnezia-wg-easy wg show

# Детальная информация
docker compose exec amnezia-wg-easy wg show all dump
```

### Мониторинг логов в реальном времени

```bash
# Все логи
docker compose logs -f

# Последние 100 строк
docker compose logs -f --tail=100

# Только ошибки
docker compose logs -f | grep -i error
```

## Настройка SSL/TLS с Let's Encrypt

Для безопасного доступа к Web UI рекомендуется использовать HTTPS:

### Вариант 1: Nginx Reverse Proxy

```bash
# Установить Nginx
sudo apt install nginx certbot python3-certbot-nginx

# Создать конфигурацию
sudo nano /etc/nginx/sites-available/vpn
```

```nginx
server {
    listen 80;
    server_name vpn.example.com;

    location / {
        proxy_pass http://localhost:51821;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Включить конфигурацию
sudo ln -s /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/

# Проверить конфигурацию
sudo nginx -t

# Перезапустить Nginx
sudo systemctl restart nginx

# Получить SSL сертификат
sudo certbot --nginx -d vpn.example.com
```

### Вариант 2: Caddy (автоматический HTTPS)

```bash
# Установить Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Создать Caddyfile
sudo nano /etc/caddy/Caddyfile
```

```
vpn.example.com {
    reverse_proxy localhost:51821
}
```

```bash
# Перезапустить Caddy
sudo systemctl restart caddy
```

## Резервное копирование и восстановление

### Автоматическое резервное копирование

Создайте скрипт для автоматического бэкапа:

```bash
nano ~/backup-vpn.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/$USER/backups"
DATE=$(date +%Y%m%d-%H%M%S)
PROJECT_DIR="/home/sham/PhpstormProjects/myVPN"

mkdir -p "$BACKUP_DIR"
cd "$PROJECT_DIR"

tar -czf "$BACKUP_DIR/vpn-backup-$DATE.tar.gz" data/ .env

# Удалить бэкапы старше 30 дней
find "$BACKUP_DIR" -name "vpn-backup-*.tar.gz" -mtime +30 -delete

echo "Backup created: vpn-backup-$DATE.tar.gz"
```

```bash
# Сделать скрипт исполняемым
chmod +x ~/backup-vpn.sh

# Добавить в cron для ежедневного выполнения в 2:00 ночи
crontab -e
```

Добавьте строку:
```
0 2 * * * /home/$USER/backup-vpn.sh >> /home/$USER/backup-vpn.log 2>&1
```

### Восстановление из резервной копии

```bash
# Остановить VPN сервер
docker compose down

# Восстановить данные
cd /home/sham/PhpstormProjects/myVPN
tar -xzf /path/to/vpn-backup-YYYYMMDD-HHMMSS.tar.gz

# Запустить сервер
docker compose up -d
```

## Миграция на другой сервер

```bash
# На старом сервере:
# 1. Создать резервную копию
tar -czf vpn-full-backup.tar.gz data/ .env docker-compose.yml

# 2. Скопировать на новый сервер
scp vpn-full-backup.tar.gz user@new-server:/tmp/

# На новом сервере:
# 3. Распаковать
cd /home/sham/PhpstormProjects/myVPN
tar -xzf /tmp/vpn-full-backup.tar.gz

# 4. Обновить WG_HOST в .env на новый IP
nano .env

# 5. Запустить
docker compose up -d
```

## Оптимизация производительности

### Настройка ядра Linux

```bash
# Создать файл конфигурации
sudo nano /etc/sysctl.d/99-wireguard.conf
```

```
# IP forwarding
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Увеличить лимиты
net.core.rmem_max=2500000
net.core.wmem_max=2500000
```

```bash
# Применить настройки
sudo sysctl -p /etc/sysctl.d/99-wireguard.conf
```

### Мониторинг ресурсов

```bash
# Использование CPU и памяти
docker stats amnezia-wg-easy --no-stream

# Детальная информация
docker inspect amnezia-wg-easy
```
