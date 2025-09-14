#!/bin/bash
# ==========================================
# Script Lengkap Reload Semua Zone di Bind9
# ==========================================
# Cara Pakai:
# 1. Simpan script ini, misalnya: bind-reload-all.sh
# 2. Kasih izin eksekusi:
#       chmod +x bind-reload.sh
# 3. Jalankan:
#       ./bind-reload.sh
#
# Fitur:
# - Update serial number semua file zone (*.zone, db.*)
# - Validasi konfigurasi BIND
# - Validasi masing-masing zone
# - Reload semua zone (fallback restart kalau gagal)
# ==========================================

# Folder zone file (ubah sesuai path kamu)
ZONE_DIR="/etc/bind"
NAMED_CONF="/etc/bind/named.conf.local"

# Fungsi update serial di zone file
update_serial() {
  local file="$1"
  echo "🔄 Update serial: $file"

  # ambil serial lama
  local old_serial=$(grep -E '^[[:space:]]*[0-9]{10}[[:space:]]*;.*serial' "$file" | awk '{print $1}')

  if [[ -z "$old_serial" ]]; then
    echo "⚠️  Tidak ditemukan serial di $file, lewati."
    return
  fi

  local today=$(date +%Y%m%d)
  local base=$(echo $old_serial | cut -c1-8)
  local counter=$(echo $old_serial | cut -c9-10)

  if [[ "$base" == "$today" ]]; then
    # Naikkan counter (max 99)
    counter=$((10#$counter + 1))
    counter=$(printf "%02d" $counter)
    new_serial="${today}${counter}"
  else
    new_serial="${today}00"
  fi

  # ganti serial lama dengan yang baru
  sed -i "s/$old_serial/$new_serial/" "$file"
  echo "✅ $old_serial → $new_serial"
}

# Step 1: update serial semua zone
echo "=== [STEP 1] Update Serial Semua Zone ==="
for zonefile in $ZONE_DIR/db.* $ZONE_DIR/*.zone; do
  [[ -f "$zonefile" ]] && update_serial "$zonefile"
done

# Step 2: check konfigurasi
echo "=== [STEP 2] Check Config ==="
sudo named-checkconf
if [ $? -ne 0 ]; then
  echo "❌ Error di konfigurasi BIND. Periksa file conf!"
  exit 1
fi

# Step 3: check masing-masing zone
echo "=== [STEP 3] Check Semua Zone ==="
grep 'zone "' "$NAMED_CONF" | awk '{print $2}' | tr -d '"' | while read -r zonename; do
  zonefile=$(grep "zone \"$zonename\"" -A2 "$NAMED_CONF" | grep file | awk '{print $2}' | tr -d '";')
  echo "🔎 Cek $zonename ($zonefile)"
  sudo named-checkzone "$zonename" "$zonefile"
done

# Step 4: reload
echo "=== [STEP 4] Reload All Zone ==="
sudo rndc reload
if [ $? -eq 0 ]; then
  echo "✅ Semua zone berhasil direload!"
else
  echo "⚠️ Reload gagal, mencoba restart bind9..."
  sudo systemctl restart bind9
  if [ $? -eq 0 ]; then
    echo "✅ Bind9 berhasil direstart."
  else
    echo "❌ Gagal reload/restart. Cek log: journalctl -u bind9 -f"
    exit 1
  fi
fi
