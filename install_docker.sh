#!/bin/bash

set -e

echo "=== Docker Auto Install Script (Fresh Install) ==="

# --- Function Uninstall Docker ---
uninstall_docker() {
  echo "=== [UNINSTALL] Stop docker service ==="
  sudo systemctl stop docker || true

  echo "=== [UNINSTALL] Remove docker packages ==="
  sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker docker-engine docker.io containerd runc || true

  echo "=== [UNINSTALL] Purge config ==="
  sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || true

  echo "=== [UNINSTALL] Remove docker directories ==="
  sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg

  echo "=== [UNINSTALL] Remove user from docker group ==="
  sudo gpasswd -d $USER docker || true

  echo "✅ Docker completely uninstalled"
}

# --- Function Install Docker ---
install_docker() {
  echo "=== [1] Update system ==="
  sudo apt update -y && sudo apt upgrade -y

  echo "=== [2] Install dependencies ==="
  sudo apt install -y ca-certificates curl gnupg lsb-release

  echo "=== [3] Add Docker GPG key ==="
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo "=== [4] Add Docker repository ==="
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  echo "=== [5] Install Docker Engine + Compose ==="
  sudo apt update -y
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  echo "=== [6] Enable & start Docker service ==="
  sudo systemctl enable docker
  sudo systemctl start docker

  echo "=== [7] Add user to docker group ==="
  if groups $USER | grep -q '\bdocker\b'; then
    echo "ℹ️  User $USER already in docker group"
  else
    sudo usermod -aG docker $USER
    echo "✅ Added $USER to docker group (logout/login needed)"
  fi

  echo "=== [8] Check versions ==="
  docker --version || echo "⚠️ Docker not working"
  docker compose version || echo "⚠️ Docker Compose not working"

  echo "✅ Fresh Docker installation complete!"
}

# --- Main Logic ---
if command -v docker &> /dev/null; then
  echo "⚠️  Docker already installed, uninstalling first..."
  uninstall_docker
fi

echo "🚀 Proceeding with fresh installation..."
install_docker

echo ""
echo "=== Done ==="
echo "⚠️ Please logout and login again (or run: newgrp docker) to use Docker without sudo."
