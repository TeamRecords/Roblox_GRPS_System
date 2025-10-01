#!/usr/bin/env bash
set -euo pipefail

# Provision the GRPS backend on Ubuntu 24.04 (Vultr Dedicated Cloud).
# This script assumes you are running as root on a fresh server.

APP_USER="grps"
APP_HOME="/opt/grps"
SRC_DIR="$APP_HOME/src"
BACKEND_DIR="$APP_HOME/backend"
PYTHON_BIN="python3.12"
REPO_URL="${REPO_URL:-https://github.com/ArcFoundation/Roblox_GRPS_System.git}"

log() {
  echo "[install_backend] $*"
}

ensure_user() {
  if ! id -u "$APP_USER" >/dev/null 2>&1; then
    log "Creating system user $APP_USER"
    adduser --system --group --home "$APP_HOME" "$APP_USER"
  fi
  mkdir -p "$APP_HOME"
  chown "$APP_USER:$APP_USER" "$APP_HOME"
}

install_packages() {
  log "Updating apt cache and installing dependencies"
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt upgrade -y
  apt install -y build-essential pkg-config git curl ca-certificates rsync \
    "$PYTHON_BIN" "$PYTHON_BIN"-venv "$PYTHON_BIN"-dev python3-pip
}

clone_repo() {
  if [ ! -d "$SRC_DIR/.git" ]; then
    log "Cloning Roblox_GRPS_System repository"
    sudo -u "$APP_USER" git clone "$REPO_URL" "$SRC_DIR"
  else
    log "Repository already exists, pulling latest changes"
    sudo -u "$APP_USER" git -C "$SRC_DIR" pull --ff-only
  fi
  rsync -a --delete "$SRC_DIR/backend/" "$BACKEND_DIR/"
  chown -R "$APP_USER:$APP_USER" "$BACKEND_DIR"
}

setup_venv() {
  log "Creating virtual environment"
  sudo -u "$APP_USER" "$PYTHON_BIN" -m venv "$BACKEND_DIR/venv"
  sudo -u "$APP_USER" "$BACKEND_DIR/venv/bin/pip" install --upgrade pip wheel
  sudo -u "$APP_USER" "$BACKEND_DIR/venv/bin/pip" install -r "$BACKEND_DIR/requirements.txt"
}

install_service() {
  log "Installing systemd service"
  install -m 644 "$BACKEND_DIR/deploy/grps-backend.service" /etc/systemd/system/grps-backend.service
  systemctl daemon-reload
  systemctl enable grps-backend
}

main() {
  install_packages
  ensure_user
  clone_repo
  setup_venv
  install_service
  log "Done. Create $BACKEND_DIR/.env and start the service: systemctl start grps-backend"
}

main "$@"
