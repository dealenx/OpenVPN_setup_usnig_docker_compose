# OpenVPN Server Setup для Dokploy (Обновлено 07.01.2025)

## Описание
Автоматизированная настройка OpenVPN сервера с использованием Docker Compose для деплоя в Dokploy.

## Особенности
- Автоматическая инициализация при первом запуске
- Автоматическое создание первого клиента
- Поддержка переменных окружения
- Готов для Dokploy

## Настройка для Dokploy

### 1. Переменные окружения
Установите следующие переменные окружения в Dokploy:

```
SERVER_NAME=ваш.домен.или.ip
CLIENT_NAME=имя_первого_клиента
OVPN_PASSWORD=ваш_пароль
```

### 2. Настройка порта
В настройках Dokploy укажите порт `11194/udp` для OpenVPN.

### 3. Кастомная команда (если нужно)
В разделе "Advanced" -> "Run Command" можете указать:
```
/scripts/entrypoint.sh
```

## Ручной запуск (локально)

1. Скопируйте `example.env` в `.env` и отредактируйте:
```bash
cp example.env .env
# Отредактируйте .env файл
```

2. Запустите:
```bash
docker-compose up -d
```

## Добавление дополнительных клиентов

```bash
# Выполните внутри контейнера
docker-compose exec openvpn /scripts/add_client.sh имя_клиента
```

## Получение конфигурации клиента

Файлы конфигурации сохраняются в `/etc/openvpn/` внутри контейнера:
```bash
# Скопировать конфигурацию наружу
docker-compose exec openvpn cat /etc/openvpn/client1.ovpn > client1.ovpn
```

## Структура проекта
```
OpenVPN_setup_using_docker_compose/
├── docker-compose.yml      # Основная конфигурация
├── scripts/
│   ├── entrypoint.sh      # Автоматическая настройка
│   └── add_client.sh      # Добавление клиентов
├── example.env            # Пример переменных окружения
└── README.md             # Эта документация
```

## Требования
- Docker и Docker Compose
- Dokploy (для автоматического деплоя)
