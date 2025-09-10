#!/bin/bash

# --- Konfigurasi dasar ---
WG_INTERFACE="wg0"
WG_SERVER_IP="202.155.95.4"
WG_SERVER_PORT="51820"
WG_SERVER_PUBLICKEY="0Ysi/GogBdT5Z6VPMspqZaRrMtuii9ly6WrgyHp3+0U="
WG_CLIENT_IP="10.0.0.$(shuf -i 10-254 -n 1)"   # auto pilih IP random
WG_DNS="1.1.1.1"
WG_CONF_DIR="/etc/wireguard"

# --- Generate keypair client ---
PRIVKEY=$(wg genkey)
PUBKEY=$(echo $PRIVKEY | wg pubkey)

# --- Tulis config client.conf ---
CLIENT_CONF="client-${WG_CLIENT_IP##*.}.conf"

cat > $CLIENT_CONF <<EOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WG_CLIENT_IP/24
DNS = $WG_DNS

[Peer]
PublicKey = $WG_SERVER_PUBLICKEY
Endpoint = $WG_SERVER_IP:$WG_SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# --- Tambahkan peer ke server runtime ---
sudo wg set $WG_INTERFACE peer $PUBKEY allowed-ips $WG_CLIENT_IP/32

# --- Tambahkan peer permanent ke wg0.conf ---
sudo tee -a $WG_CONF_DIR/$WG_INTERFACE.conf > /dev/null <<EOF

# --- Client $(basename $CLIENT_CONF .conf) ---
[Peer]
PublicKey = $PUBKEY
AllowedIPs = $WG_CLIENT_IP/32
EOF

# --- Generate QR code ---
qrencode -t ansiutf8 < $CLIENT_CONF

echo
echo "Config tersimpan di: $CLIENT_CONF"
echo "PublicKey client: $PUBKEY"
echo "Client IP: $WG_CLIENT_IP"
echo "Peer ditambahkan permanent ke $WG_CONF_DIR/$WG_INTERFACE.conf"
