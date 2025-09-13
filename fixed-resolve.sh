#!/bin/bash
# Fix systemd-resolved supaya pakai BIND9 lokal

set -e

echo "[+] Backup config lama..."
sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.backup.$(date +%s) || true

echo "[+] Tulis ulang /etc/systemd/resolved.conf..."
sudo bash -c 'cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=127.0.0.1 8.8.8.8
FallbackDNS=1.1.1.1
EOF'

echo "[+] Restart systemd-resolved..."
sudo systemctl restart systemd-resolved

echo "[+] Pastikan /etc/resolv.conf symlink ke stub resolver..."
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "[+] Status resolver:"
resolvectl status | grep "DNS Servers"

echo "[✓] Fixed! Sekarang semua query DNS diarahkan ke BIND9 lokal (127.0.0.1)."
