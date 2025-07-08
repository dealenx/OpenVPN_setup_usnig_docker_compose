FROM kylemanna/openvpn

# Копируем скрипты и устанавливаем права
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Устанавливаем entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"] 