#!/bin/bash
set -e

echo "=== OpenVPN Auto-Setup Entrypoint ==="

# Проверяем переменные окружения
SERVER_NAME=${SERVER_NAME:-"vpn.example.com"}
CLIENT_NAME=${CLIENT_NAME:-"client1"}

echo "Сервер: $SERVER_NAME"
echo "Клиент: $CLIENT_NAME"

# Проверяем, инициализирован ли OpenVPN
if [ ! -f "/etc/openvpn/pki/ca.crt" ]; then
    echo "=== Первый запуск: инициализация OpenVPN ==="
    
    # Генерируем конфигурацию OpenVPN
    echo "Генерируем конфигурацию сервера..."
    ovpn_genconfig -e 'duplicate-cn' -e 'topology subnet' -u udp://$SERVER_NAME
    
    # Инициализируем PKI без пароля и с автоматическим подтверждением
    echo "Инициализируем PKI без пароля..."
    echo "yes" | ovpn_initpki nopass
    
    echo "=== Создаем первого клиента ==="
    # Создаем клиента без пароля для автоматизации
    easyrsa build-client-full "$CLIENT_NAME" nopass
    
    # Экспортируем конфигурацию клиента
    ovpn_getclient "$CLIENT_NAME" > "/etc/openvpn/$CLIENT_NAME.ovpn"
    
    echo "Конфигурация клиента сохранена: /etc/openvpn/$CLIENT_NAME.ovpn"
    echo "=== Инициализация завершена ==="
else
    echo "=== OpenVPN уже инициализирован ==="
fi

# Выводим информацию о доступных конфигурациях
echo "=== Доступные конфигурации клиентов ==="
ls -la /etc/openvpn/*.ovpn 2>/dev/null || echo "Конфигурации клиентов не найдены"

# Запускаем OpenVPN сервер
echo "=== Запускаем OpenVPN сервер ==="
exec ovpn_run 