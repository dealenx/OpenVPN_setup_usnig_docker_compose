#!/bin/bash
set -e

# Скрипт для выполнения внутри контейнера OpenVPN

# Функция для проверки существования клиента
check_client_exists() {
    local client_name=$1
    # Проверяем наличие сертификата клиента
    if [ -f "/etc/openvpn/pki/issued/$client_name.crt" ]; then
        return 0  # Клиент существует
    else
        return 1  # Клиент не существует
    fi
}

# Получение имени клиента из переменной окружения или аргумента
if [ -n "$1" ]; then
    CLIENT="$1"
    echo "Используется имя клиента из аргумента: $CLIENT"
elif [ -n "$CLIENT_NAME" ]; then
    CLIENT="$CLIENT_NAME"
    echo "Используется имя клиента из переменной окружения: $CLIENT"
else
    echo "Ошибка: Необходимо указать имя клиента!"
    echo "Использование: $0 <имя_клиента>"
    echo "Или установите переменную окружения CLIENT_NAME"
    exit 1
fi

# Проверка на пустое имя
if [ -z "$CLIENT" ]; then
    echo "Ошибка: Имя клиента не может быть пустым!"
    exit 1
fi

# Проверка существования клиента
if check_client_exists "$CLIENT"; then
    echo "Клиент '$CLIENT' уже существует!"
    if [ "$FORCE_RECREATE" = "true" ]; then
        echo "Принудительное пересоздание клиента..."
    else
        echo "Для пересоздания клиента установите переменную FORCE_RECREATE=true"
        exit 1
    fi
    
    echo "Удаляем существующий сертификат клиента..."
    easyrsa revoke "$CLIENT" || true
    rm -f "/etc/openvpn/pki/issued/$CLIENT.crt" || true
    rm -f "/etc/openvpn/pki/private/$CLIENT.key" || true
    rm -f "/etc/openvpn/pki/reqs/$CLIENT.req" || true
fi

echo "Создание клиента '$CLIENT'..."

# Создание сертификата клиента
if [ "$NO_PASSWORD" = "true" ]; then
    echo "Создание сертификата без пароля..."
    easyrsa build-client-full "$CLIENT" nopass
else
    echo "Создание сертификата с паролем (будет запрошен)..."
    easyrsa build-client-full "$CLIENT"
fi

# Экспорт конфигурационного файла клиента
echo "Экспорт конфигурационного файла..."
ovpn_getclient "$CLIENT" > "/tmp/$CLIENT.ovpn"

# Проверка успешного создания
if [ -f "/tmp/$CLIENT.ovpn" ]; then
    echo "✓ Клиент '$CLIENT' успешно создан."
    echo "✓ Конфигурационный файл создан: /tmp/$CLIENT.ovpn"
    echo ""
    echo "Для получения файла выполните на хосте:"
    echo "docker-compose exec openvpn cat /tmp/$CLIENT.ovpn > $CLIENT.ovpn"
else
    echo "✗ Ошибка при создании конфигурационного файла!"
    exit 1
fi 