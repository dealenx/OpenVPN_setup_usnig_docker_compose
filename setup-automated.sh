#!/bin/bash
set -e

# Функция для проверки существования конфигурации
check_config_exists() {
    # Проверяем все критически важные файлы PKI
    if [ -f "/etc/openvpn/openvpn.conf" ] && \
       [ -f "/etc/openvpn/pki/ca.crt" ] && \
       [ -f "/etc/openvpn/pki/issued/server.crt" ] && \
       [ -f "/etc/openvpn/pki/private/server.key" ] && \
       [ -f "/etc/openvpn/pki/dh.pem" ]; then
        echo "OpenVPN конфигурация и все файлы PKI существуют, пропускаем инициализацию..."
        return 0
    else
        echo "Отсутствуют файлы PKI, выполняем полную инициализацию..."
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
    
    # Используем expect для автоматического ввода, указываем "server" как имя сертификата
    expect -c "
        set timeout 300
        spawn ovpn_initpki nopass
        expect {
            \"*Common Name*\" {
                send \"server\r\"
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
    
    # Проверка успешной инициализации всех необходимых файлов
    echo "Проверка созданных файлов PKI..."
    
    REQUIRED_FILES=(
        "/etc/openvpn/openvpn.conf"
        "/etc/openvpn/pki/ca.crt"
        "/etc/openvpn/pki/issued/server.crt"
        "/etc/openvpn/pki/private/server.key"
        "/etc/openvpn/pki/dh.pem"
        "/etc/openvpn/pki/ta.key"
    )
    
    MISSING_FILES=()
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        echo "✓ Настройка OpenVPN завершена успешно!"
        echo "✓ Все необходимые файлы PKI созданы."
    else
        echo "✗ Ошибка при настройке OpenVPN!"
        echo "Отсутствующие файлы:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
}

# Основная логика
echo "Проверка содержимого /etc/openvpn:"
ls -la /etc/openvpn/ || echo "Директория /etc/openvpn пуста или не существует"

if ! check_config_exists; then
    setup_openvpn
else
    echo "Конфигурация найдена, запускаем сервер..."
fi

echo "Итоговое содержимое /etc/openvpn:"
ls -la /etc/openvpn/
echo "Содержимое /etc/openvpn/pki:"
ls -la /etc/openvpn/pki/ || echo "PKI директория не существует"

# Запуск переданной команды
exec "$@" 