#!/bin/bash
# Script install RDP (XRDP + XFCE) di Ubuntu 24.04
# Tested on fresh VPS

# Pastikan root
if [ "$EUID" -ne 0 ]; then
  echo "Jalankan script ini sebagai root (sudo su)"
  exit
fi

echo "[1/6] Update sistem..."
apt update && apt upgrade -y

echo "[2/6] Install XFCE4 desktop..."
apt install -y xfce4 xfce4-goodies

echo "[3/6] Install XRDP..."
apt install -y xrdp

echo "[4/6] Enable XRDP service..."
systemctl enable xrdp
systemctl start xrdp

echo "[5/6] Set XFCE sebagai default session..."
echo "xfce4-session" > /home/$SUDO_USER/.xsession
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.xsession

echo "[6/6] Buka firewall port RDP (3389)..."
ufw allow 3389/tcp

echo "======================================="
echo " Installasi selesai!"
echo " Gunakan RDP client (mstsc di Windows)"
echo " IP VPS:3389"
echo " Username: $SUDO_USER"
echo " Password: password user VPS"
echo "======================================="
