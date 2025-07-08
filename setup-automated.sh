#!/bin/bash
set -e

# Функция для проверки существования конфигурации
check_config_exists() {
    if [ -f "/etc/openvpn/openvpn.conf" ]; then
        echo "OpenVPN конфигурация уже существует, пропускаем инициализацию..."
        return 0
    else
        return 1
    fi
}

# Функция автоматической настройки
setup_openvpn() {
    echo "Начинаем автоматическую настройку OpenVPN для сервера: $SERVER_NAME"
    
    # Генерация конфигурации OpenVPN
    echo "Генерируем конфигурацию сервера..."
    ovpn_genconfig -e 'duplicate-cn' -e 'topology subnet' -u udp://$SERVER_NAME
    
    # Инициализация PKI без пароля (автоматический режим)
    echo "Инициализируем PKI в автоматическом режиме..."
    expect << EOF
spawn ovpn_initpki nopass
expect "Common Name*" { send "$EASYRSA_REQ_CN\r" }
expect eof
EOF
    
    echo "Настройка OpenVPN завершена!"
}

# Основная логика
if ! check_config_exists; then
    setup_openvpn
else
    echo "Конфигурация найдена, запускаем сервер..."
fi

# Запуск переданной команды
exec "$@" 