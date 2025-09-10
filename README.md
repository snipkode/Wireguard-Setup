## WireGuard + NAT + UFW Cheat Sheet

Install

apt update && apt install -y wireguard ufw qrencode

IP Forwarding

echo "net.ipv4.ip_forward=1" >> /etc/ufw/sysctl.conf
sysctl -p

WireGuard Server

wg genkey | tee server_private.key | wg pubkey > server_public.key
nano /etc/wireguard/wg0.conf

[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820

wg-quick up wg0
systemctl enable wg-quick@wg0

Firewall + NAT

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 51820/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000:3010/tcp
nano /etc/ufw/before.rules

Tambahkan sebelum *filter:

*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
COMMIT

ufw enable && ufw reload

Tambah Client

wg genkey | tee client_private.key | wg pubkey > client_public.key
wg set wg0 peer <CLIENT_PUBLIC_KEY> allowed-ips 10.0.0.2/32
nano client.conf

[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25

qrencode -t ansiutf8 < client.conf

Port Hanya dari VPN

ufw deny in on eth0 to any port 3306
ufw allow in on wg0 to any port 3306


⚡ Done → VPN + NAT + Firewall siap.

