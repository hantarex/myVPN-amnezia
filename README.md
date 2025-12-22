# AmnesiaWG - VPN Сервер на базе AmneziaWG

Простой и безопасный VPN сервер с веб-интерфейсом управления на базе WireGuard/AmneziaWG.

## Особенности

- ✅ Простая установка через Docker Compose
- ✅ Русскоязычный веб-интерфейс управления
- ✅ Автоматическая генерация конфигураций клиентов
- ✅ QR-коды для быстрого подключения
- ✅ Поддержка AmneziaWG (обфусцированный WireGuard)
- ✅ Статистика подключений и трафика

## Быстрый старт

### Предварительные требования

- Сервер на Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- Docker и Docker Compose
- Открытые порты: 51820/UDP (VPN), 51821/TCP (Web UI)
- Root доступ или sudo права

### Установка Docker (если не установлен)

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Выйдите и войдите снова для применения изменений.

### Установка VPN сервера

1. **Создать .env файл**:
```bash
cp .env.example .env
```

2. **Сгенерировать хеш пароля**:
```bash
docker run --rm ghcr.io/w0rng/amnezia-wg-easy wgpw 'мой_пароль'
```

3. **Узнать публичный IP**:
```bash
curl -4 ifconfig.me
```

4. **Отредактировать .env**:
```bash
nano .env
```

Обязательно заполните:
- `PASSWORD_HASH` - хеш пароля из шага 2
- `WG_HOST` - ваш публичный IP из шага 3

5. **Запустить сервер**:
```bash
docker compose up -d
```

6. **Открыть Web UI**:
```
http://ВАШ_IP:51821
```

## Управление

### Основные команды

```bash
# Запуск
docker compose up -d

# Остановка
docker compose down

# Просмотр логов
docker compose logs -f

# Обновление
docker compose pull && docker compose up -d

# Резервная копия
tar -czf backup.tar.gz data/
```

### Добавление клиентов

1. Войдите в Web UI (http://ВАШ_IP:51821)
2. Нажмите "Добавить клиент"
3. Введите имя клиента
4. Скачайте конфигурацию или отсканируйте QR-код

## Конфигурация

Все настройки находятся в файле `.env`. Основные параметры:

| Параметр | Описание | По умолчанию |
|----------|----------|--------------|
| `LANG` | Язык интерфейса | `ru` |
| `PASSWORD_HASH` | Хеш пароля для Web UI | - |
| `WG_HOST` | Публичный IP/домен сервера | - |
| `WG_PORT` | UDP порт VPN | `51820` |
| `WEB_PORT` | TCP порт Web UI | `51821` |
| `WG_DEFAULT_DNS` | DNS для клиентов | `1.1.1.1` |

Полный список параметров смотрите в `.env.example`.

## Безопасность

### Рекомендации:

1. **Используйте сильный пароль** (минимум 16 символов)
2. **Настройте firewall**:
```bash
sudo ufw allow 51820/udp
sudo ufw allow 51821/tcp
sudo ufw enable
```

3. **Ограничьте доступ к Web UI** по IP:
   - Используйте SSH туннель
   - Настройте nginx reverse proxy с базовой аутентификацией
   - Используйте VPN для доступа к панели управления

4. **Регулярно обновляйте**:
```bash
docker compose pull
docker compose up -d
```

5. **Делайте резервные копии**:
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz data/
```

## Устранение неполадок

### Контейнер не запускается

```bash
# Проверить логи
docker compose logs

# Проверить права
sudo chown -R $USER:$USER data/

# Проверить порты
sudo netstat -tulpn | grep -E '51820|51821'
```

### Клиенты не могут подключиться

```bash
# Проверить WireGuard интерфейс
docker compose exec amnezia-wg-easy wg show

# Проверить IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # должно быть 1

# Проверить firewall
sudo iptables -L -n -v
```

### Web UI недоступен

```bash
# Проверить статус контейнера
docker compose ps

# Проверить порт
curl http://localhost:51821

# Проверить логи
docker compose logs -f
```

## Обновление

```bash
# Остановить сервер
docker compose down

# Обновить образ
docker compose pull

# Запустить с новой версией
docker compose up -d

# Проверить логи
docker compose logs -f
```

## Удаление

```bash
# Остановить и удалить контейнеры
docker compose down

# Удалить конфигурации (ОСТОРОЖНО!)
rm -rf data/

# Удалить .env файл
rm .env
```

## Лицензия

Проект основан на [w0rng/amnezia-wg-easy](https://github.com/w0rng/amnezia-wg-easy).

## Дополнительная документация

- [Детальная настройка](docs/SETUP.md)
- [Решение проблем](docs/TROUBLESHOOTING.md)
