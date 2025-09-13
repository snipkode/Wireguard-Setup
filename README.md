# WireGuard + NAT + UFW Setup Guide

## 🚀 Quick Installation

```bash
apt update && apt install -y wireguard ufw qrencode
```

## 🔧 Enable IP Forwarding

```bash
echo "net.ipv4.ip_forward=1" >> /etc/ufw/sysctl.conf
sysctl -p
```

## 🔑 Setup WireGuard Server

### Generate Server Keys
```bash
wg genkey | tee server_private.key | wg pubkey > server_public.key
```

### Create Server Configuration
```bash
nano /etc/wireguard/wg0.conf
```

Add the following content:
```ini
[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820
```

### Start and Enable WireGuard
```bash
wg-quick up wg0
systemctl enable wg-quick@wg0
```

## 🛡️ Configure Firewall + NAT

### Reset and Configure UFW
```bash
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 51820/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000:3010/tcp
```

### Setup NAT Rules
```bash
nano /etc/ufw/before.rules
```

Add this **before** the `*filter` line:
```bash
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
COMMIT
```

### Enable Firewall
```bash
ufw enable && ufw reload
```

## 👤 Add Client Configuration

### Generate Client Keys
```bash
wg genkey | tee client_private.key | wg pubkey > client_public.key
```

### Add Client to Server
```bash
wg set wg0 peer <CLIENT_PUBLIC_KEY> allowed-ips 10.0.0.2/32
```

### Create Client Configuration File
```bash
nano client.conf
```

Add the following content:
```ini
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Generate QR Code for Mobile
```bash
qrencode -t ansiutf8 < client.conf
```

## 🔒 Restrict Ports to VPN Only

Block port access from external interface but allow from VPN:
```bash
ufw deny in on eth0 to any port 3306
ufw allow in on wg0 to any port 3306
```

## ✅ Summary

Your VPN server is now configured with:
- **WireGuard VPN** running on port 51820
- **NAT masquerading** for internet access through VPN
- **UFW firewall** with proper rules
- **Port restrictions** for internal services
- **QR code generation** for easy mobile setup

---

**🎉 VPN + NAT + Firewall setup complete!**
