#!/bin/bash
set -e

# Получаем имя клиента из аргумента или переменной окружения
CLIENT_NAME=${1:-${CLIENT_NAME:-"newclient"}}

echo "=== Добавление нового клиента: $CLIENT_NAME ==="

# Проверяем, что OpenVPN инициализирован
if [ ! -f "/etc/openvpn/pki/ca.crt" ]; then
    echo "Ошибка: OpenVPN не инициализирован!"
    exit 1
fi

# Создаем клиента без пароля
echo "Создаем сертификат клиента..."
easyrsa build-client-full "$CLIENT_NAME" nopass

# Экспортируем конфигурацию клиента
echo "Экспортируем конфигурацию..."
ovpn_getclient "$CLIENT_NAME" > "/etc/openvpn/$CLIENT_NAME.ovpn"

echo "Клиент '$CLIENT_NAME' создан!"
echo "Конфигурация сохранена: /etc/openvpn/$CLIENT_NAME.ovpn" 