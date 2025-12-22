# Решение распространенных проблем

## Проблемы с установкой

### Docker daemon не запускается

**Симптомы**: Ошибка `Cannot connect to the Docker daemon`

**Решение**:
```bash
# Проверить статус Docker
sudo systemctl status docker

# Запустить Docker
sudo systemctl start docker

# Включить автозапуск
sudo systemctl enable docker

# Проверить снова
sudo systemctl status docker
```

### Ошибка прав доступа

**Симптомы**: `permission denied while trying to connect to the Docker daemon socket`

**Решение**:
```bash
# Добавить пользователя в группу docker
sudo usermod -aG docker $USER

# Применить изменения (нужно выйти и войти заново, или использовать)
newgrp docker

# Проверить
docker ps
```

### Конфликт портов

**Симптомы**: `bind: address already in use`

**Решение**:
```bash
# Проверить, какой процесс использует порт
sudo netstat -tulpn | grep 51820
sudo netstat -tulpn | grep 51821

# ИЛИ используя ss
sudo ss -tulpn | grep 51820

# Остановить конфликтующий процесс
sudo kill <PID>

# ИЛИ изменить порты в .env файле
nano .env
# Измените WG_PORT и WEB_PORT на свободные порты
```

### Отсутствует модуль TUN

**Симптомы**: `cannot open TUN/TAP dev /dev/net/tun`

**Решение**:
```bash
# Проверить наличие /dev/net/tun
ls -l /dev/net/tun

# Если отсутствует, создать
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 0666 /dev/net/tun

# Для VPS: убедитесь, что TUN/TAP включен в панели управления хостинга
```

## Проблемы с подключением

### Клиенты не могут подключиться к VPN

**Симптомы**: Timeout при подключении, ошибка handshake

**Диагностика**:
```bash
# 1. Проверить, работает ли контейнер
docker compose ps

# 2. Проверить логи
docker compose logs -f

# 3. Проверить WireGuard интерфейс
docker compose exec amnezia-wg-easy wg show
```

**Решение 1: Проверить IP forwarding**
```bash
# Проверить текущее значение
cat /proc/sys/net/ipv4/ip_forward  # должно быть 1

# Если 0, включить
sudo sysctl -w net.ipv4.ip_forward=1

# Сделать постоянным
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Решение 2: Проверить NAT и iptables**
```bash
# Проверить правила NAT
sudo iptables -t nat -L -n -v

# Добавить правило MASQUERADE (замените eth0 на ваш интерфейс)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Сохранить правила
# Ubuntu/Debian
sudo apt install iptables-persistent
sudo netfilter-persistent save

# CentOS/RHEL
sudo service iptables save
```

**Решение 3: Проверить firewall**
```bash
# UFW
sudo ufw status
sudo ufw allow 51820/udp
sudo ufw reload

# firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload

# Для облачных провайдеров (AWS, GCP, Azure)
# Убедитесь, что Security Groups/Firewall Rules разрешают UDP 51820
```

**Решение 4: Проверить WG_HOST**
```bash
# Убедитесь, что WG_HOST в .env соответствует вашему публичному IP
curl -4 ifconfig.me

# Сравните с значением в .env
grep WG_HOST .env

# Если отличается - исправьте и перезапустите
nano .env
docker compose restart
```

### VPN подключается, но нет интернета

**Симптомы**: Успешное подключение к VPN, но веб-сайты не загружаются

**Решение 1: Проверить DNS**
```bash
# Проверить настройку DNS в .env
grep WG_DEFAULT_DNS .env

# Попробовать другой DNS
# В .env:
WG_DEFAULT_DNS=8.8.8.8

# Перезапустить
docker compose restart

# Пересоздать конфигурацию клиента
```

**Решение 2: Проверить маршрутизацию**
```bash
# В контейнере
docker compose exec amnezia-wg-easy ip route

# Проверить, что трафик идет через правильный интерфейс
docker compose exec amnezia-wg-easy iptables -t nat -L POSTROUTING -n -v
```

**Решение 3: MTU проблемы**
```bash
# В .env попробуйте уменьшить MTU
WG_MTU=1280

# Перезапустить и пересоздать клиентские конфигурации
docker compose restart
```

### Периодические разрывы соединения

**Симптомы**: VPN отключается через некоторое время

**Решение**:
```bash
# Включить keepalive в .env
WG_PERSISTENT_KEEPALIVE=25

# Перезапустить и пересоздать конфигурации
docker compose restart
```

## Проблемы с Web UI

### Web UI недоступен

**Симптомы**: Не удается открыть http://IP:51821

**Диагностика**:
```bash
# 1. Проверить статус контейнера
docker compose ps
# Должен быть "Up"

# 2. Проверить логи
docker compose logs -f
# Искать ошибки

# 3. Проверить, слушает ли порт
sudo netstat -tulpn | grep 51821
# ИЛИ
curl http://localhost:51821
```

**Решение 1: Перезапустить контейнер**
```bash
docker compose restart
docker compose logs -f
```

**Решение 2: Проверить firewall**
```bash
# UFW
sudo ufw allow 51821/tcp

# firewalld
sudo firewall-cmd --permanent --add-port=51821/tcp
sudo firewall-cmd --reload
```

**Решение 3: Проверить WEB_IP**
```bash
# В .env убедитесь:
WEB_IP=0.0.0.0

# Не используйте 127.0.0.1, если нужен доступ извне
```

### Не могу войти в Web UI

**Симптомы**: Неверный пароль, хотя пароль правильный

**Решение**:
```bash
# 1. Пересоздать хеш пароля
docker run --rm ghcr.io/w0rng/amnezia-wg-easy wgpw 'новый_пароль'

# 2. Обновить PASSWORD_HASH в .env
nano .env

# 3. Перезапустить
docker compose restart

# 4. Подождать 10-15 секунд и попробовать снова
```

### Web UI медленно загружается

**Решение**:
```bash
# Проверить ресурсы
docker stats amnezia-wg-easy --no-stream

# Если CPU/RAM на пределе:
# 1. Отключить статистику трафика
UI_TRAFFIC_STATS=false

# 2. Перезапустить
docker compose restart
```

## Проблемы с производительностью

### Низкая скорость VPN

**Диагностика**:
```bash
# Проверить нагрузку на сервер
top
htop  # если установлен

# Проверить использование Docker контейнером
docker stats amnezia-wg-easy
```

**Решение 1: Оптимизировать MTU**
```bash
# Попробуйте разные значения
WG_MTU=1420  # по умолчанию
WG_MTU=1500  # для быстрых сетей
WG_MTU=1280  # для медленных/мобильных сетей

# Перезапустить
docker compose restart
```

**Решение 2: Отключить keepalive**
```bash
# Если не нужна стабильность за NAT
WG_PERSISTENT_KEEPALIVE=0

docker compose restart
```

**Решение 3: Проверить сервер**
```bash
# Скорость сетевого интерфейса
ethtool eth0 | grep Speed

# Ping до сервера
ping -c 10 ВАШ_IP

# Пропускная способность (с другой машины)
iperf3 -c ВАШ_IP -p 5201
```

### Высокое использование CPU

**Решение**:
```bash
# Проверить количество клиентов
docker compose exec amnezia-wg-easy wg show | grep peer

# Отключить метрики Prometheus
ENABLE_PROMETHEUS_METRICS=false

# Отключить статистику трафика
UI_TRAFFIC_STATS=false

# Перезапустить
docker compose restart
```

## Проблемы с данными

### Потеря конфигураций после перезапуска

**Симптомы**: После `docker compose down` все клиенты исчезли

**Причина**: Volume не смонтирован правильно

**Решение**:
```bash
# Проверить volume в docker-compose.yml
grep -A 2 "volumes:" docker-compose.yml
# Должно быть: - ./data:/etc/wireguard

# Проверить наличие данных
ls -la data/

# Если директория пуста, восстановить из бэкапа
tar -xzf backup.tar.gz

# Перезапустить
docker compose up -d
```

### Ошибка прав доступа к data/

**Симптомы**: `Permission denied` при записи в data/

**Решение**:
```bash
# Проверить владельца
ls -ld data/

# Изменить владельца (замените на вашего пользователя)
sudo chown -R $USER:$USER data/

# Дать правильные права
chmod 755 data/
```

### Восстановление из резервной копии

```bash
# Остановить контейнер
docker compose down

# Удалить старые данные
rm -rf data/

# Восстановить из бэкапа
tar -xzf backup-YYYYMMDD.tar.gz

# Проверить права
sudo chown -R $USER:$USER data/

# Запустить
docker compose up -d
```

## Диагностические команды

### Полная диагностика системы

```bash
# Статус Docker
sudo systemctl status docker

# Статус контейнера
docker compose ps
docker compose logs --tail=50

# WireGuard интерфейс
docker compose exec amnezia-wg-easy wg show all

# Сеть в контейнере
docker compose exec amnezia-wg-easy ip addr
docker compose exec amnezia-wg-easy ip route

# Iptables правила
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Системные параметры
sysctl net.ipv4.ip_forward
sysctl net.ipv4.conf.all.src_valid_mark

# Использование ресурсов
docker stats amnezia-wg-easy --no-stream

# Сетевые соединения
sudo netstat -tulpn | grep -E '51820|51821'
```

### Экспорт логов для поддержки

```bash
# Собрать всю диагностическую информацию
mkdir -p ~/vpn-diagnostics
cd ~/vpn-diagnostics

# Логи контейнера
docker compose logs > docker-logs.txt

# Конфигурация (без паролей)
grep -v PASSWORD_HASH /home/sham/PhpstormProjects/myVPN/.env > config.txt

# Сетевая информация
ip addr > network.txt
ip route >> network.txt
sudo iptables -L -n -v > iptables.txt
sudo iptables -t nat -L -n -v > iptables-nat.txt

# WireGuard
docker compose exec amnezia-wg-easy wg show > wireguard.txt

# Системная информация
uname -a > system.txt
docker version >> system.txt
docker compose version >> system.txt

# Создать архив
tar -czf vpn-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz *.txt
```

## Переустановка

Если ничего не помогает, полная переустановка:

```bash
# 1. Создать резервную копию
tar -czf vpn-backup-emergency.tar.gz data/ .env

# 2. Остановить и удалить все
docker compose down -v
docker system prune -a --volumes

# 3. Удалить проект
cd ..
rm -rf myVPN

# 4. Начать заново
# Следуйте инструкциям в README.md

# 5. Восстановить данные из бэкапа (если нужно)
tar -xzf vpn-backup-emergency.tar.gz
```

## Получение помощи

Если проблема не решена:

1. Соберите диагностическую информацию (см. выше)
2. Проверьте [GitHub Issues](https://github.com/w0rng/amnezia-wg-easy/issues)
3. Создайте новый Issue с детальным описанием проблемы и логами
