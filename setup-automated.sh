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
    rm -rf /etc/openvpn/*
    
    # Генерируем конфигурацию сервера
    echo "Генерируем конфигурацию сервера..."
    ovpn_genconfig -u udp://$SERVER_NAME
    
    # Инициализация PKI без паролей (полностью автоматически)
    echo "Инициализируем PKI автоматически..."
    
    # Используем переменные окружения для автоматизации
    export EASYRSA_BATCH=1
    export EASYRSA_REQ_CN="$SERVER_NAME"
    
    # Создаем PKI структуру без паролей
    echo -e "\n\n\n\n\n\n\n" | ovpn_initpki nopass
    
    # Проверка успешной инициализации
    echo "Проверка созданных файлов PKI..."
    
    REQUIRED_FILES=(
        "/etc/openvpn/openvpn.conf"
        "/etc/openvpn/pki/ca.crt"
        "/etc/openvpn/pki/issued/server.crt"
        "/etc/openvpn/pki/private/server.key"
        "/etc/openvpn/pki/dh.pem"
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
        
        # Показываем созданные файлы
        echo "Созданные файлы:"
        ls -la /etc/openvpn/pki/issued/
        ls -la /etc/openvpn/pki/private/
    else
        echo "✗ Ошибка при настройке OpenVPN!"
        echo "Отсутствующие файлы:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
        
        # Показываем что есть для диагностики
        echo "Содержимое /etc/openvpn:"
        ls -la /etc/openvpn/ || true
        echo "Содержимое /etc/openvpn/pki:"
        ls -la /etc/openvpn/pki/ || true
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