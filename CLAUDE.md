# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Язык общения / Communication Language

**Весь код и коммуникация ведутся на русском языке.**

All code and communication should be conducted in Russian language.

## Описание проекта / Project Description

Проект **AmnesizWG** - VPN сервер на базе WireGuard с использованием Docker Compose.

## Команды разработки / Development Commands

### Первоначальная настройка
```bash
# Создать .env файл из шаблона
cp .env.example .env

# Сгенерировать хеш пароля
docker run --rm ghcr.io/w0rng/amnezia-wg-easy wgpw 'ВАШ_ПАРОЛЬ'

# Узнать публичный IP
curl -4 ifconfig.me

# Узнать сетевой интерфейс
ip route | grep default | awk '{print $5}'

# Отредактировать .env и заполнить параметры
nano .env
```

### Управление контейнером
```bash
# Запустить VPN сервер
docker compose up -d

# Остановить VPN сервер
docker compose down

# Перезапустить
docker compose restart

# Посмотреть логи
docker compose logs -f

# Обновить до последней версии
docker compose pull && docker compose up -d
```

### Резервное копирование
```bash
# Создать резервную копию
tar -czf amnezia-wg-backup-$(date +%Y%m%d).tar.gz data/

# Восстановить из копии
tar -xzf amnezia-wg-backup-YYYYMMDD.tar.gz
```

### Диагностика
```bash
# Проверить WireGuard интерфейс
docker compose exec amnezia-wg-easy wg show

# Войти в контейнер
docker compose exec amnezia-wg-easy sh
```

## Архитектура / Architecture

### Компоненты
- **Docker Container**: ghcr.io/w0rng/amnezia-wg-easy
  - Web UI для управления (Node.js)
  - WireGuard/AmneziaWG VPN сервер

### Сеть
- UDP порт 51820 - VPN трафик
- TCP порт 51821 - Web UI
- Внутренняя сеть IPv4: 10.8.0.0/24
- Внутренняя сеть IPv6: fd42:42:42::/64 (опционально)

### Хранилище
- `./data` → `/etc/wireguard` - конфигурации WireGuard

### Требования
- Docker 20.10+
- Docker Compose v2.0+
- Linux Kernel 5.6+ (для WireGuard)
- Открытые порты: 51820/UDP, 51821/TCP
- IPv6 поддержка в ядре (опционально, для IPv6 VPN)