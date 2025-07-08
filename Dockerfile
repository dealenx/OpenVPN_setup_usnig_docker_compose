FROM kylemanna/openvpn:latest

# Установка переменных окружения для автоматизации
ENV SERVER_NAME=vpn.example.com
ENV EASYRSA_BATCH=1
ENV EASYRSA_REQ_CN="OpenVPN CA"

# Установка дополнительных пакетов для автоматизации
RUN apt-get update && apt-get install -y expect && rm -rf /var/lib/apt/lists/*

# Создание директорий
RUN mkdir -p /etc/openvpn

# Копирование скрипта настройки
COPY setup-automated.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-automated.sh

# Точка входа для автоматической настройки
ENTRYPOINT ["/usr/local/bin/setup-automated.sh"]
CMD ["ovpn_run"] 