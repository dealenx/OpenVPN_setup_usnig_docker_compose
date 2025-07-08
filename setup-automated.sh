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
    echo "Инициализируем PKI пошагово..."
    
    # Сначала инициализируем PKI структуру
    easyrsa init-pki
    
    # Создаем CA без пароля
    echo "Создание CA сертификата..."
    EASYRSA_REQ_CN="$EASYRSA_REQ_CN" easyrsa --batch build-ca nopass
    
    # Генерируем DH параметры
    echo "Генерация DH параметров..."
    easyrsa gen-dh
    
    # Создаем сертификат сервера с именем "server"
    echo "Создание сертификата сервера..."
    easyrsa --batch build-server-full server nopass
    
    # Генерируем tls-auth ключ
    echo "Генерация TLS-auth ключа..."
    openvpn --genkey --secret /etc/openvpn/pki/ta.key
    
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