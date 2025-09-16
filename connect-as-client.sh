#!/bin/bash

WG_IF="wg0"
PRIVATE_KEY_FILE="/etc/wireguard/client.key"
PRIVATE_KEY="AFPVo75r5uVsKtIJ+FCRriiPSoGr681pz4VSwuubGGI="
ADDRESS="10.0.0.207/24"
DNS="1.1.1.1"
ENDPOINT="202.155.95.4:51820"
PUBLIC_KEY_SERVER="0Ysi/GogBdT5Z6VPMspqZaRrMtuii9ly6WrgyHp3+0U="

prepare_key() {
    # Pastikan direktori ada
    sudo mkdir -p /etc/wireguard

    # Tulis private key ke file
    echo "$PRIVATE_KEY" | sudo tee $PRIVATE_KEY_FILE >/dev/null

    # Atur permission agar aman
    sudo chmod 600 $PRIVATE_KEY_FILE
}

start() {
    echo "[*] Preparing key file..."
    prepare_key

    echo "[*] Starting WireGuard client..."

    # Hapus interface lama kalau ada
    sudo ip link del $WG_IF 2>/dev/null

    # Buat interface baru
    sudo ip link add dev $WG_IF type wireguard

    # Set IP client
    sudo ip addr add $ADDRESS dev $WG_IF

    # Konfigurasi WireGuard peer
    sudo wg set $WG_IF private-key $PRIVATE_KEY_FILE \
        peer $PUBLIC_KEY_SERVER \
        endpoint $ENDPOINT \
        allowed-ips 0.0.0.0/0,::/0 \
        persistent-keepalive 25

    # Aktifkan interface
    sudo ip link set up dev $WG_IF

    # Set DNS (langsung override resolv.conf karena resolvconf ga ada)
    echo "nameserver $DNS" | sudo tee /etc/resolv.conf >/dev/null

    echo "[*] WireGuard client started."
}

stop() {
    echo "[*] Stopping WireGuard client..."
    sudo ip link del $WG_IF 2>/dev/null
}

status() {
    echo "[*] WireGuard status:"
    sudo wg show
    echo
    ip addr show dev $WG_IF
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; start ;;
    status)  status ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        ;;
esac
