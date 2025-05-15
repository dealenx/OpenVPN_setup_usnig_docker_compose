#!/bin/bash
set -e

# Ask for client name
read -p "Enter new client name: " CLIENT
echo "Creating client '$CLIENT' (you will be prompted to set a password)..."

# Create client certificate (with password)
docker-compose exec openvpn easyrsa build-client-full "$CLIENT"

# Export the client config file
docker-compose exec openvpn ovpn_getclient "$CLIENT" > "$CLIENT.ovpn"

echo "Client '$CLIENT' created."
echo "Config file saved as: $CLIENT.ovpn"