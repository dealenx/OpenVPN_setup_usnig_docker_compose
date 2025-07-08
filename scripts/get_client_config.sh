#!/bin/bash
set -e

# Получаем имя клиента из аргумента
CLIENT_NAME=${1:-"client1"}

echo "=== Получение конфигурации клиента: $CLIENT_NAME ==="

# Проверяем, что конфигурация существует
if [ ! -f "/etc/openvpn/$CLIENT_NAME.ovpn" ]; then
    echo "Ошибка: Конфигурация клиента '$CLIENT_NAME' не найдена!"
    echo "Доступные конфигурации:"
    ls -1 /etc/openvpn/*.ovpn 2>/dev/null | xargs -n1 basename | sed 's/.ovpn$//' || echo "Нет доступных конфигураций"
    exit 1
fi

# Выводим конфигурацию
echo "Конфигурация клиента '$CLIENT_NAME':"
echo "================================="
cat "/etc/openvpn/$CLIENT_NAME.ovpn" 