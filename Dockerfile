FROM kylemanna/openvpn:latest

# Установка переменных окружения для автоматизации
ENV SERVER_NAME=vpn.example.com
ENV EASYRSA_BATCH=1
ENV EASYRSA_REQ_CN="OpenVPN CA"

# Установка дополнительных пакетов для автоматизации (Alpine Linux использует apk)
RUN apk add --no-cache expect

# Создание директорий
RUN mkdir -p /etc/openvpn

# Копирование скриптов
COPY setup-automated.sh /usr/local/bin/
COPY add_user_internal.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-automated.sh /usr/local/bin/add_user_internal.sh

# Точка входа для автоматической настройки
ENTRYPOINT ["/usr/local/bin/setup-automated.sh"]
CMD ["ovpn_run"] 