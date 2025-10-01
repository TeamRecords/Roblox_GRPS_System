# Deploying the GRPS Python Backend on Vultr Ubuntu 24.04

This guide targets a fresh **Vultr Dedicated Cloud** instance running **Ubuntu 24.04 LTS**. It walks through provisioning the FastAPI backend as a hardened systemd service behind Nginx. Adjust the steps for High-Frequency or Cloud Compute plans as required.

## 1. Server Preparation

1. **Update base packages**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y build-essential pkg-config git curl ca-certificates
   ```
2. **Install Python 3.12 toolchain** (Ubuntu 24.04 ships with Python 3.12)
   ```bash
   sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip
   sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
   ```
3. **Create a deployment user** (optional but recommended)
   ```bash
   sudo adduser --system --group --home /opt/grps grps
   sudo mkdir -p /opt/grps
   sudo chown grps:grps /opt/grps
   ```
4. **Firewall** (UFW) – expose only SSH (22) and HTTPS (443). HTTP (80) is optional if using automatic TLS provisioning later.
   ```bash
   sudo apt install -y ufw
   sudo ufw allow OpenSSH
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

## 2. Automated Installation (Optional)

The repository ships with `backend/deploy/install_backend.sh`, which automates the
package installs, repository clone, virtual environment creation, and systemd
unit installation. Run it as root on a fresh host:

```bash
cd /opt
sudo curl -L -o install_backend.sh https://raw.githubusercontent.com/ArcFoundation/Roblox_GRPS_System/main/backend/deploy/install_backend.sh
sudo bash install_backend.sh
```

Set `REPO_URL` before invoking the script if you mirror the repository:

```bash
sudo REPO_URL=git@github.com:your-org/Roblox_GRPS_System.git bash install_backend.sh
```

After the script exits, create `/opt/grps/backend/.env` (see Section 6) and
start the service with `sudo systemctl start grps-backend`.

## 3. Directory Layout

Deploy the backend under `/opt/grps/backend` with an isolated virtual environment:

```
/opt/grps
└── backend
    ├── app/           # FastAPI application package
    ├── venv/          # Python virtual environment (created below)
    ├── .env           # Environment variables (filled with production secrets)
    ├── requirements.txt
    ├── deploy/
    │   ├── VULTR_UBUNTU24.md
    │   ├── install_backend.sh
    │   └── grps-backend.service
    └── ...
```

## 4. Obtain the Codebase

```bash
sudo -u grps git clone https://github.com/<YOUR_ORG>/Roblox_GRPS_System.git /opt/grps/src
sudo -u grps cp -R /opt/grps/src/backend /opt/grps/backend
```

> If you already use a private Git remote, configure SSH keys for the `grps` user before cloning.

## 5. Create the Virtual Environment

```bash
cd /opt/grps/backend
sudo -u grps python3 -m venv venv
sudo -u grps ./venv/bin/pip install --upgrade pip wheel
sudo -u grps ./venv/bin/pip install -r requirements.txt
```

## 6. Configure Environment Variables

Create `/opt/grps/backend/.env` with production values. Use Neon, RDS, or another PostgreSQL service accessible from the Vultr instance.

```env
ENVIRONMENT=production
API_HOST=0.0.0.0
API_PORT=8000
DATABASE_URL=postgresql+asyncpg://grps:<password>@<db-host>:5432/grps
ROBLOX_GROUP_ID=<group-id>
ROBLOX_OPEN_CLOUD_API_KEY=<rbx-open-cloud-api-key>
ROBLOX_UNIVERSE_ID=<universe-id>
ROBLOX_DATASTORE_NAME=GRPS_Points
ROBLOX_DATASTORE_SCOPE=global
ROBLOX_DATASTORE_PREFIX=player:
INBOUND_API_KEYS=rbx-ingest-key-1,rbx-ingest-key-2
ALLOWED_ORIGINS=https://automation.example.com,https://dashboard.example.com
AUTOMATION_SIGNATURE_SECRET=<optional-hmac-secret>
WEBHOOK_VERIFICATION_KEY=<optional-webhook-key>
```

> Do **not** commit the `.env` file to Git. Use `chmod 600 /opt/grps/backend/.env` to restrict access.

## 7. Systemd Service

1. Copy the sample service definition (included in this repo at `backend/deploy/grps-backend.service`) into `/etc/systemd/system/grps-backend.service`:
   ```bash
   sudo cp /opt/grps/backend/deploy/grps-backend.service /etc/systemd/system/
   sudo chown root:root /etc/systemd/system/grps-backend.service
   ```
2. Reload systemd and enable the unit:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now grps-backend
   ```
3. Inspect logs:
   ```bash
   journalctl -u grps-backend -f
   ```

The service executes Uvicorn with the packaged application (`backend.app.main:app`) and reads the `.env` file via `pydantic-settings`.

## 8. Reverse Proxy with Nginx (Optional but Recommended)

```bash
sudo apt install -y nginx
sudo tee /etc/nginx/sites-available/grps-backend.conf >/dev/null <<'NGINX'
server {
    listen 80;
    server_name grps-backend.example.com;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:8000;
    }
}
NGINX
sudo ln -s /etc/nginx/sites-available/grps-backend.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Add HTTPS with Let’s Encrypt + Certbot if desired:
```bash
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d grps-backend.example.com
```

## 9. Health Checks

- Local: `curl http://127.0.0.1:8000/health/live`
- Through Nginx: `curl https://grps-backend.example.com/health/live`

Both should return `{"status":"ok"}` (see `backend/app/routes/health.py`).

## 10. Updating the Service

```bash
sudo systemctl stop grps-backend
sudo -u grps git -C /opt/grps/src pull
sudo -u grps rsync -a --delete /opt/grps/src/backend/ /opt/grps/backend/
sudo -u grps ./venv/bin/pip install -r requirements.txt
sudo systemctl start grps-backend
```

For zero-downtime deploys, use two directories (blue/green) and switch the systemd `WorkingDirectory` between releases.

## 11. Troubleshooting

- **Service fails to start** – run `sudo -u grps ./venv/bin/python -m backend` inside `/opt/grps/backend` to surface import errors.
- **Database connectivity** – ensure inbound rules on the database allow the Vultr server’s public IP.
- **Firewall blocks Roblox** – Roblox cloud IP ranges change; keep inbound traffic restricted to Roblox webhooks or trusted proxies.
- **Performance tuning** – scale vertically or place Uvicorn behind Gunicorn with multiple workers (`uvicorn.workers.UvicornWorker`). Adjust the systemd `ExecStart` accordingly.

With these steps the backend runs as a managed Linux service, restarts on boot, and survives failures via systemd’s restart policy.
