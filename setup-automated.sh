#!/bin/bash
set -e

# Функция для проверки существования конфигурации
check_config_exists() {
    if [ -f "/etc/openvpn/openvpn.conf" ] && [ -f "/etc/openvpn/pki/ca.crt" ]; then
        echo "OpenVPN конфигурация и PKI уже существуют, пропускаем инициализацию..."
        return 0
    else
        return 1
    fi
}

# Функция автоматической настройки
setup_openvpn() {
    echo "Начинаем автоматическую настройку OpenVPN для сервера: $SERVER_NAME"
    
    # Очистка существующих файлов если они есть
    echo "Очистка старых конфигурационных файлов..."
    rm -rf /etc/openvpn/pki
    rm -f /etc/openvpn/openvpn.conf
    
    # Генерация конфигурации OpenVPN
    echo "Генерируем конфигурацию сервера..."
    ovpn_genconfig -e 'duplicate-cn' -e 'topology subnet' -u udp://$SERVER_NAME
    
    # Инициализация PKI без пароля (автоматический режим)
    echo "Инициализируем PKI в автоматическом режиме..."
    
    # Используем expect для автоматического ввода
    expect -c "
        set timeout 300
        spawn ovpn_initpki nopass
        expect {
            \"*Common Name*\" {
                send \"$EASYRSA_REQ_CN\r\"
                exp_continue
            }
            \"*Enter PEM pass phrase*\" {
                send \"\r\"
                exp_continue
            }
            \"*CA creation complete*\" {
                puts \"PKI инициализирован успешно\"
            }
            timeout {
                puts \"Таймаут при инициализации PKI\"
                exit 1
            }
            eof
        }
    "
    
    # Проверка успешной инициализации
    if [ -f "/etc/openvpn/pki/ca.crt" ] && [ -f "/etc/openvpn/openvpn.conf" ]; then
        echo "✓ Настройка OpenVPN завершена успешно!"
    else
        echo "✗ Ошибка при настройке OpenVPN!"
        exit 1
    fi
}

# Основная логика
if ! check_config_exists; then
    setup_openvpn
else
    echo "Конфигурация найдена, запускаем сервер..."
fi

# Запуск переданной команды
exec "$@" 