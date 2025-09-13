#!/bin/bash
# ============================================
# Auto Setup WireGuard + NAT + UFW Firewall
# Safe version with modes: fresh or update
# ============================================

MODE=$1   # fresh | update
WG_PORT=51820
WG_NET="10.0.0.0/24"
WG_INTERFACE="wg0"
PUB_IFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\w+')

if [[ "$MODE" == "fresh" ]]; then
    echo "[MODE] Fresh install"

    apt update -y
    apt install -y wireguard ufw qrencode

    echo "[INFO] Enabling IP forwarding..."
    sed -i '/net.ipv4.ip_forward/d' /etc/ufw/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/ufw/sysctl.conf
    sysctl -p

    echo "[INFO] Generating WireGuard server keys..."
    mkdir -p /etc/wireguard
    cd /etc/wireguard
    umask 077
    wg genkey | tee server_private.key | wg pubkey > server_public.key
    SERVER_PRIV=$(cat server_private.key)
    SERVER_PUB=$(cat server_public.key)

    echo "[INFO] Creating new WireGuard config..."
    cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PrivateKey = $SERVER_PRIV
ListenPort = $WG_PORT
EOF

    chmod 600 /etc/wireguard/${WG_INTERFACE}.conf
    systemctl enable wg-quick@${WG_INTERFACE}
    systemctl restart wg-quick@${WG_INTERFACE}

    echo "[INFO] Resetting and configuring UFW..."
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    ufw allow 22/tcp
    ufw allow ${WG_PORT}/udp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000:3010/tcp
fi

if [[ "$MODE" == "update" ]]; then
    echo "[MODE] Update only (keep existing config)"
    apt install -y ufw
fi

# Apply NAT rules (common for both modes)
BEFORE_RULES="/etc/ufw/before.rules"
if ! grep -q "WireGuard NAT" $BEFORE_RULES; then
  sed -i '1i \
*nat\n\
:POSTROUTING ACCEPT [0:0]\n\
# WireGuard NAT\n\
-A POSTROUTING -s '"$WG_NET"' -o '"$PUB_IFACE"' -j MASQUERADE\n\
COMMIT\n' $BEFORE_RULES
fi

if ! grep -q "ufw-before-forward -i wg0" $BEFORE_RULES; then
  sed -i '/\*filter/a \
# allow forwarding for wg0\n\
-A ufw-before-forward -i wg0 -j ACCEPT\n\
-A ufw-before-forward -o wg0 -j ACCEPT' $BEFORE_RULES
fi

ufw --force enable
ufw reload

echo "[DONE] Setup complete."
