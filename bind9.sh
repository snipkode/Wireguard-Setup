#!/bin/bash
# Script otomatis konfigurasi DNS server BIND9 di Ubuntu
# Domain : namadomain.co.id
# Nameserver: ns1.namadomain.co.id
# VPS IP : 123.123.123.123

ZONE_DIR="/etc/bind"
DOMAIN="homelab.co.id"
NS_HOST="ns1"
IPV4="172.20.10.2"
REVERSE_ZONE="2.10.20.in-addr.arpa"
REV_FILE="$ZONE_DIR/db.$(echo $IPV4 | cut -d. -f1-3)"
FWD_FILE="$ZONE_DIR/db.$DOMAIN"

echo "[+] Update & install BIND9..."
apt update && apt install -y bind9 bind9utils bind9-doc

echo "[+] Backup konfigurasi lama (sekali saja)..."
if [ ! -f "$ZONE_DIR/named.conf.local.bak" ]; then
    cp $ZONE_DIR/named.conf.local $ZONE_DIR/named.conf.local.bak
fi

echo "[+] Tambah konfigurasi zone kalau belum ada..."
if ! grep -q "$DOMAIN" $ZONE_DIR/named.conf.local; then
cat <<EOF >> $ZONE_DIR/named.conf.local

zone "$DOMAIN" {
    type master;
    file "$FWD_FILE";
};
EOF
fi

if ! grep -q "$REVERSE_ZONE" $ZONE_DIR/named.conf.local; then
cat <<EOF >> $ZONE_DIR/named.conf.local

zone "$REVERSE_ZONE" {
    type master;
    file "$REV_FILE";
};
EOF
fi

echo "[+] Buat zona forward $DOMAIN..."
cat <<EOF > $FWD_FILE
\$TTL    604800
@       IN      SOA     $NS_HOST.$DOMAIN. admin.$DOMAIN. (
                        3         ; Serial
                        604800    ; Refresh
                        86400     ; Retry
                        2419200   ; Expire
                        604800 )  ; Negative Cache TTL
;
@       IN      NS      $NS_HOST.$DOMAIN.
@       IN      A       $IPV4
$NS_HOST IN      A       $IPV4
www     IN      A       $IPV4
EOF

echo "[+] Buat zona reverse $REVERSE_ZONE..."
cat <<EOF > $REV_FILE
\$TTL    604800
@       IN      SOA     $NS_HOST.$DOMAIN. admin.$DOMAIN. (
                        1
                        604800
                        86400
                        2419200
                        604800 )
;
@       IN      NS      $NS_HOST.$DOMAIN.
$(echo $IPV4 | cut -d. -f4)      IN      PTR     $DOMAIN.
EOF

echo "[+] Cek konfigurasi..."
named-checkconf
named-checkzone $DOMAIN $FWD_FILE
named-checkzone $REVERSE_ZONE $REV_FILE

echo "[+] Restart bind9..."
systemctl restart bind9
systemctl enable bind9

echo "[+] Allow DNS port on UFW..."
ufw allow 53/tcp
ufw allow 53/udp

echo "[✓] Selesai!"
echo "    - Domain : $DOMAIN"
echo "    - Nameserver : $NS_HOST.$DOMAIN → $IPV4"
