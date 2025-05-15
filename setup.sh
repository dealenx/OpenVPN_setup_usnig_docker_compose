#!/bin/bash
set -e
VPN_DATA_DIR="./openvpn-data/conf"

# Ask for the VPN server's domain or IP
read -p "Enter your VPN server domain or IP: " SERVER_NAME

echo "Creating OpenVPN data directory..."
mkdir -p "$VPN_DATA_DIR"

# Generate OpenVPN configuration
echo "Generating OpenVPN server config for $SERVER_NAME..."
docker run -v "$PWD/openvpn-data/conf":/etc/openvpn --rm kylemanna/openvpn \
  ovpn_genconfig -u udp://$SERVER_NAME

# Initialize PKI with password protection (will prompt you)
echo "Initializing the PKI (you will be prompted to set a passphrase)..."
docker run -v "$PWD/openvpn-data/conf":/etc/openvpn --rm -it kylemanna/openvpn \
  ovpn_initpki

# Start the OpenVPN container
echo "Starting OpenVPN server with Docker Compose..."
docker-compose up -d

echo "OpenVPN server setup complete and running."