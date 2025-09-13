#!/bin/bash
# Fix BIND9 config & restart service

set -e

echo "[+] Backup config lama..."
mkdir -p /etc/bind/backup
cp -r /etc/bind/named.conf* /etc/bind/backup/ 2>/dev/null || true

echo "[+] Pastikan file include ada..."
touch /etc/bind/named.conf.local
touch /etc/bind/named.conf.default-zones

echo "[+] Buat named.conf utama..."
cat <<'EOF' > /etc/bind/named.conf
// Main BIND configuration
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF

echo "[+] Buat named.conf.options (IPv4 only, fix query-source & IPv6 issue)..."
cat <<'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    // Disable IPv6 listener (server hanya IPv4)
    listen-on-v6 { none; };
    // prefer-ipv6 no;

    // Aktifkan DNSSEC
    dnssec-validation auto;

    // Forwarder ke DNS publik (Google & Cloudflare)
    forwarders {
        8.8.8.8;
        8.8.4.4;
        1.1.1.1;
    };

    auth-nxdomain no;
    recursion yes;
};
EOF

echo "[+] Buat named.conf.default-zones (default zone bawaan)..."
cat <<'EOF' > /etc/bind/named.conf.default-zones
zone "." {
    type hint;
    file "/usr/share/dns/root.hints";
};

zone "localhost" {
    type master;
    file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
    type master;
    file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
    type master;
    file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
    type master;
    file "/etc/bind/db.255";
};
EOF

echo "[+] Cek config dengan named-checkconf..."
if ! named-checkconf; then
    echo "[!] Ada error di config, cek manual!"
    exit 1
fi

echo "[+] Restart service..."
systemctl restart named
systemctl enable named

echo "[✓] BIND9 fixed & running. Cek status dengan: systemctl status named"
