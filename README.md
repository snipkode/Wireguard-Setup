## WireGuard + NAT + UFW (Summary)

1. Setup Dasar
	•	Install paket:

apt update && apt install -y wireguard ufw qrencode


	•	Aktifkan IP forwarding:

echo "net.ipv4.ip_forward=1" >> /etc/ufw/sysctl.conf
sysctl -p



2. Konfigurasi WireGuard Server
	•	Generate keypair:

wg genkey | tee server_private.key | wg pubkey > server_public.key


	•	Buat /etc/wireguard/wg0.conf:

[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820


	•	Jalankan:

wg-quick up wg0
systemctl enable wg-quick@wg0



3. NAT & Firewall (UFW)
	•	Reset & set default:

ufw --force reset
ufw default deny incoming
ufw default allow outgoing


	•	Allow port publik:

ufw allow 22/tcp
ufw allow 51820/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000:3010/tcp   # contoh range


	•	Tambah NAT di /etc/ufw/before.rules:

*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
COMMIT


	•	Reload:

ufw enable && ufw reload



4. Tambah Client
	•	Generate keypair:

wg genkey | tee client_private.key | wg pubkey > client_public.key


	•	Tambah ke server:

wg set wg0 peer <CLIENT_PUBLIC_KEY> allowed-ips 10.0.0.2/32


	•	Buat client.conf:

[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25


	•	Opsional QR:

qrencode -t ansiutf8 < client.conf



5. Port Hanya Bisa dari VPN
	•	Contoh MySQL hanya dari VPN:

ufw deny in on eth0 to any port 3306
ufw allow in on wg0 to any port 3306



⸻

⚡ Dengan ini:
	•	Internet publik hanya bisa akses port yang kamu allow.
	•	Port sensitif hanya bisa lewat VPN.
	•	Client bisa generate config + QR dengan mudah.

