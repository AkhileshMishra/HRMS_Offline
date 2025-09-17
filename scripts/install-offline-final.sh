#!/usr/bin/env bash
set -euo pipefail

# =========================================
# HRMS v15 Offline Installer (Improved)
# =========================================
#
# Usage (example):
#   bash install-offline-improved.sh \
#     --bundle-tar /path/to/hrms-offline-bundle-final.tar.gz \
#     --site-name site.local \
#     --with-payments \
#     --use-prebuilt-assets
#
# Optional env vars for non-interactive site creation:
#   export DB_ROOT_PWD="root"
#   export ADMIN_PWD="admin"
#
# Flags:
#   --bundle-tar <file>       # REQUIRED. Path to the offline bundle .tar.gz
#   --bench-home <dir>        # Where to create the bench (default: $HOME/hrms-bench)
#   --site-name <name>        # New site name (default: site.local)
#   --with-payments           # Install payments app if present in bundle
#   --use-prebuilt-assets     # Use prebuilt assets from bundle (if available)
#   --production              # Configure supervisor+nginx (offline)
#
BUNDLE_TAR=""
BENCH_HOME="$HOME/hrms-bench"
SITE_NAME="site.local"
WITH_PAYMENTS=0
USE_PREBUILT_ASSETS=0
SETUP_PRODUCTION=0
INSTALL_ROOT="/opt/hrms-offline"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle-tar) BUNDLE_TAR="${2:-}"; shift 2;;
    --bench-home) BENCH_HOME="${2:-}"; shift 2;;
    --site-name) SITE_NAME="${2:-}"; shift 2;;
    --with-payments) WITH_PAYMENTS=1; shift;;
    --use-prebuilt-assets) USE_PREBUILT_ASSETS=1; shift;;
    --production) SETUP_PRODUCTION=1; shift;;
    *) echo "Unknown flag: $1"; exit 1;;
  esac
done

if [[ -z "${BUNDLE_TAR}" || ! -f "${BUNDLE_TAR}" ]]; then
  echo "ERROR: --bundle-tar is required and must point to an existing .tar.gz"
  exit 1
fi

# --- Better error visibility
trap 'echo "❌ Install failed at line $LINENO"; exit 1' ERR

echo "==> Installer starting"
echo "    Bundle:         ${BUNDLE_TAR}"
echo "    Bench home:     ${BENCH_HOME}"
echo "    Site name:      ${SITE_NAME}"
echo "    With payments:  ${WITH_PAYMENTS}"
echo "    Use prebuilt assets: ${USE_PREBUILT_ASSETS}"
echo "    Production:     ${SETUP_PRODUCTION}"
echo

# --- OS check (warn only)
if ! grep -qi "Ubuntu 22.04" /etc/os-release; then
  echo "WARNING: This script is designed for Ubuntu 22.04 (Jammy). Continuing anyway..."
fi

# --- Friendlier extraction + cleaner basename
echo "==> Extracting bundle (this may take a few minutes)..."
sudo mkdir -p "${INSTALL_ROOT}"
sudo chown -R "$USER":"$USER" "${INSTALL_ROOT}"
tar -xzf "${BUNDLE_TAR}" -C "${INSTALL_ROOT}" --checkpoint=1000 --checkpoint-action=dot
echo
BUNDLE_BASENAME="$(tar -tf "${BUNDLE_TAR}" 2>/dev/null | head -1 | cut -d/ -f1)"
if [[ -z "${BUNDLE_BASENAME}" ]]; then
  echo "ERROR: Could not determine bundle root directory from tarball"
  exit 1
fi
BUNDLE_DIR="${INSTALL_ROOT}/${BUNDLE_BASENAME}"
echo "==> Bundle unpacked at: ${BUNDLE_DIR}"

# --- Disable external apt sources (optional but recommended for air-gapped installs)
echo "==> Configuring local APT repository (disabling others to avoid timeouts)..."
sudo mkdir -p /etc/apt/sources.list.d/disabled
# Move other .list files aside (if any)
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
  [[ -e "$f" ]] || continue
  sudo mv "$f" /etc/apt/sources.list.d/disabled/ 2>/dev/null || true
done
echo "deb [trusted=yes] file:${BUNDLE_DIR}/debs ./" | sudo tee /etc/apt/sources.list.d/local-offline.list >/dev/null

# --- Robust, non-interactive apt and offline-only behavior
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -o Dpkg::Options::=--force-confnew -y update
sudo apt-get -y install \
  git python3 python3-venv python3-dev python3-pip build-essential \
  libffi-dev libssl-dev libmysqlclient-dev \
  mariadb-server redis-server nginx xfonts-75dpi xfonts-base || true

# wkhtmltopdf (prefer wkhtmltox* from bundle if present)
if ls "${BUNDLE_DIR}/debs"/wkhtmltox*.deb >/dev/null 2>&1; then
  echo "==> Installing wkhtmltopdf (wkhtmltox) from bundle..."
  sudo dpkg -i "${BUNDLE_DIR}/debs"/wkhtmltox*.deb || sudo apt -f install -y
else
  echo "==> Installing wkhtmltopdf from local repo..."
  sudo apt-get install -y wkhtmltopdf || sudo apt -f install -y
fi

# --- MariaDB charset/collation
echo "==> Ensuring MariaDB utf8mb4 config..."
MYSQL_CNF="/etc/mysql/my.cnf"
CHARSET_MARKER="character-set-server = utf8mb4"
if ! sudo grep -q "${CHARSET_MARKER}" "${MYSQL_CNF}" 2>/dev/null; then
  sudo tee -a "${MYSQL_CNF}" >/dev/null <<'EOF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF
fi

# --- Ensure services are up before site creation
echo "==> Starting and configuring services..."
sudo systemctl enable mariadb redis-server >/dev/null 2>&1 || true
sudo systemctl restart mariadb
sudo systemctl restart redis-server

# Wait for DB socket
echo "==> Waiting for MariaDB to be ready..."
for i in {1..30}; do
  mysqladmin ping >/dev/null 2>&1 && break
  sleep 1
done

# --- Node & Yarn from bundle tools
echo "==> Installing Node & Yarn from bundle tools..."
sudo mkdir -p /opt/node
NODE_TAR="$(ls "${BUNDLE_DIR}/tools"/node-v*-linux-x64.tar.xz | head -1)"
sudo tar -xJf "${NODE_TAR}" -C /opt/node --strip-components=1
YARN_CJS="$(ls "${BUNDLE_DIR}/tools"/yarn-*.cjs | head -1)"
sudo cp "${YARN_CJS}" /usr/local/lib/yarn-standalone.cjs
sudo tee /usr/local/bin/yarn >/dev/null <<'EOF'
#!/usr/bin/env bash
exec /opt/node/bin/node /usr/local/lib/yarn-standalone.cjs "$@"
EOF
sudo chmod +x /usr/local/bin/yarn
if ! grep -q "/opt/node/bin" ~/.bashrc; then
  echo 'export PATH=/opt/node/bin:$PATH' >> ~/.bashrc
fi
export PATH="/opt/node/bin:$PATH"

# JS build headroom (avoid OOM on smaller servers)
export NODE_OPTIONS="${NODE_OPTIONS:-} --max_old_space_size=2048"

yarn --version || { echo "Yarn failed to run"; exit 1; }

# --- Bench from wheelhouse (strictly offline)
echo "==> Installing bench (offline, from wheelhouse)..."
python3 -m venv "$HOME/bench-env"
source "$HOME/bench-env/bin/activate"

# --- CRITICAL: Offline pip policy for bench init
echo "==> Configuring offline pip environment for bench init..."
OFF_PIP="${BUNDLE_DIR}/wheels/pip-offline.conf"
cat > "${OFF_PIP}" <<EOF
[global]
no-index = true
find-links = ${BUNDLE_DIR}/wheels
EOF
export PIP_CONFIG_FILE="${OFF_PIP}"
export PIP_NO_INDEX=1
export PIP_FIND_LINKS="${BUNDLE_DIR}/wheels"

# Install bench with offline configuration
pip install -c "${BUNDLE_DIR}/wheels/constraints.txt" "frappe-bench>=5,<6" 2>/dev/null || pip install "frappe-bench>=5,<6"

# --- Init bench with local frappe (now with offline pip config)
echo "==> bench init at ${BENCH_HOME} (skip assets)..."
bench init "${BENCH_HOME}" \
  --frappe-path "${BUNDLE_DIR}/repos/frappe" \
  --python "$(which python3)" \
  --skip-assets
cd "${BENCH_HOME}"

# Force bench pip to always use the local wheelhouse
echo -e "[pip]\nno-index = true\nfind-links = ${BUNDLE_DIR}/wheels" > pip.conf
bench set-config -g pip_conf "$(pwd)/pip.conf"

# --- Get apps from local repos
echo "==> Adding apps from local repos..."
bench get-app "${BUNDLE_DIR}/repos/erpnext"
if [[ "${WITH_PAYMENTS}" == "1" && -d "${BUNDLE_DIR}/repos/payments" ]]; then
  bench get-app "${BUNDLE_DIR}/repos/payments"
fi
bench get-app "${BUNDLE_DIR}/repos/hrms"

# === COMPLETE YARN OFFLINE CONFIGURATION ===
echo "==> Configuring Yarn for complete offline operation..."

# CRITICAL: Clean any global mirror pointing to bad paths (like /npm-offline)
yarn config delete yarn-offline-mirror -g || true

# Create bench-local mirror symlink to bundle's npm-offline
ln -sfn "${BUNDLE_DIR}/npm-offline" "${BENCH_HOME}/npm-offline"

# Force per-app configuration with pruning prevention
for app in "${BENCH_HOME}/apps/frappe" "${BENCH_HOME}/apps/erpnext" "${BENCH_HOME}/apps/hrms"; do
  if [[ -d "$app" ]]; then
    ( cd "$app" \
      && yarn config set yarn-offline-mirror "${BENCH_HOME}/npm-offline" \
      && yarn config set yarn-offline-mirror-pruning false )
  fi
done

# Set environment variables for both yarn and npm
export YARN_CACHE_FOLDER="${BENCH_HOME}/npm-offline"
export npm_config_cache="${BENCH_HOME}/npm-offline"

# Fail fast if anything tries network access
yarn config set network-timeout 1 >/dev/null 2>&1 || true

echo "==> Complete yarn offline configuration applied"

# --- Create site & install apps
echo "==> Creating site: ${SITE_NAME}"
if [[ -n "${DB_ROOT_PWD:-}" && -n "${ADMIN_PWD:-}" ]]; then
  bench new-site "${SITE_NAME}" --db-root-password "${DB_ROOT_PWD}" --admin-password "${ADMIN_PWD}"
else
  bench new-site "${SITE_NAME}"
fi

echo "==> Installing apps into ${SITE_NAME} (order: erpnext -> payments? -> hrms)"
bench --site "${SITE_NAME}" install-app erpnext
if [[ "${WITH_PAYMENTS}" == "1" && -d "${BUNDLE_DIR}/repos/payments" ]]; then
  bench --site "${SITE_NAME}" install-app payments
fi
bench --site "${SITE_NAME}" install-app hrms

# --- Assets
if [[ "${USE_PREBUILT_ASSETS}" == "1" && -d "${BUNDLE_DIR}/prebuilt-assets" && -n "$(ls -A "${BUNDLE_DIR}/prebuilt-assets" 2>/dev/null)" ]]; then
  echo "==> Using prebuilt assets from bundle..."
  rsync -a "${BUNDLE_DIR}/prebuilt-assets/" sites/assets/
  bench clear-cache
else
  echo "==> Building assets (offline)..."
  bench build
fi

# --- Optional: production setup (supervisor + nginx) fully offline
if [[ "${SETUP_PRODUCTION}" == "1" ]]; then
  echo "==> Setting up production services (supervisor + nginx)..."
  # Ensure 'bench' from current venv is visible to sudo
  sudo env "PATH=$PATH" bench setup production "$USER" --yes
  sudo systemctl enable nginx || true
  sudo systemctl restart nginx || true
  # Different distros use supervisor or supervisord service name
  sudo systemctl restart supervisor || sudo systemctl restart supervisord || true
fi

# --- Finalize
bench --site "${SITE_NAME}" enable-scheduler
bench --site "${SITE_NAME}" set-maintenance-mode off

echo
echo "============================================"
echo "✅ Offline install complete!"
echo "To run the dev server now:"
echo "  cd ${BENCH_HOME}"
echo "  bench use ${SITE_NAME}"
echo "  bench start   # then open http://localhost:8000"
if [[ "${SETUP_PRODUCTION}" == "1" ]]; then
  echo
  echo "Production mode enabled. Nginx + Supervisor configured."
fi
echo "============================================"

