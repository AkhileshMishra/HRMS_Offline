# HRMS v15 Offline Installation Troubleshooting

This guide helps resolve common issues encountered during offline HRMS v15 installation.

## 🚨 Installation Failures

### Issue #1: Installation Fails at Line 75
**Symptoms:**
```
❌ Install failed at line 75
```

**Root Cause:** Bundle extraction issues or permission problems

**Solutions:**
```bash
# Check disk space
df -h .
# Need at least 10GB free

# Check bundle integrity
tar -tzf hrms-v15-complete-offline.tar.gz | head -5
# Should list bundle contents

# Manual extraction test
mkdir test-extract
tar -xzf hrms-v15-complete-offline.tar.gz -C test-extract
ls test-extract/
# Should show hrms-offline-bundle directory

# Fix permissions
sudo chown -R $USER:$USER /opt/hrms-offline/
```

### Issue #2: Bundle Extraction Timeout
**Symptoms:**
- Installation hangs during extraction
- No progress indicators

**Solutions:**
```bash
# Run with verbose output
sudo -E bash -x ./install-offline-final.sh \
  --bundle-tar ./hrms-v15-complete-offline.tar.gz \
  --site-name mysite.local

# Monitor system resources
top
# Check CPU and memory usage

# Extract manually if needed
sudo mkdir -p /opt/hrms-offline
sudo tar -xzf hrms-v15-complete-offline.tar.gz -C /opt/hrms-offline
```

## 🐍 Python Environment Issues

### Issue #3: Bench Initialization Fails
**Symptoms:**
```
ERROR: Could not find a version that satisfies the requirement wheel
```

**Root Cause:** Missing bootstrap wheels for offline installation

**Solutions:**
```bash
# Verify bootstrap wheels exist
ls /opt/hrms-offline/hrms-offline-bundle/wheels/ | grep -E "(pip|wheel|setuptools|six)"
# Should show these packages

# Set offline pip configuration
export PIP_CONFIG_FILE="/opt/hrms-offline/hrms-offline-bundle/wheels/pip-offline.conf"
export PIP_NO_INDEX=1
export PIP_FIND_LINKS="/opt/hrms-offline/hrms-offline-bundle/wheels"

# Retry bench initialization
bench init ~/hrms-bench --frappe-path /opt/hrms-offline/hrms-offline-bundle/repos/frappe --skip-assets
```

### Issue #4: Missing Build Dependencies
**Symptoms:**
```
ERROR: Could not find a version that satisfies the requirement flit_core>=3.4,<4
```

**Root Cause:** Missing modern Python build backends

**Solutions:**
```bash
# Check if build dependencies exist
ls /opt/hrms-offline/hrms-offline-bundle/wheels/ | grep -E "(flit_core|editables|tomli)"
# Should show these packages

# If missing, download manually (requires internet)
pip download -d /opt/hrms-offline/hrms-offline-bundle/wheels/ \
  "flit_core>=3.4,<4" "editables>=0.3" "tomli>=1.1.0"

# Retry installation
```

## 🧶 Yarn and Frontend Issues

### Issue #5: Yarn Network Access Errors
**Symptoms:**
```
error Error: https://registry.yarnpkg.com/package-name: ESOCKETTIMEDOUT
```

**Root Cause:** Yarn not configured for offline mode

**Solutions:**
```bash
# Apply complete yarn offline configuration
cd ~/hrms-bench

# Clean global configuration
yarn config delete yarn-offline-mirror -g || true

# Set up symlink
ln -sfn /opt/hrms-offline/hrms-offline-bundle/npm-offline ~/hrms-bench/npm-offline

# Configure each app
for app in apps/frappe apps/erpnext apps/hrms apps/payments; do
  if [[ -d "$app" ]]; then
    (cd "$app" && yarn config set yarn-offline-mirror "$(pwd)/../../npm-offline")
  fi
done

# Set environment variables
export YARN_CACHE_FOLDER="~/hrms-bench/npm-offline"
export npm_config_cache="~/hrms-bench/npm-offline"
yarn config set network-timeout 1
```

### Issue #6: Missing NPM Packages
**Symptoms:**
```
error Can't make a request in offline mode ("https://registry.yarnpkg.com/onscan.js/-/onscan.js-1.5.2.tgz")
```

**Root Cause:** Required packages missing from offline mirror

**Solutions:**
```bash
# Identify missing packages
cd ~/hrms-bench/apps/erpnext
grep -A10 "dependencies" package.json

# Temporary fix: Remove missing dependencies
cp package.json package.json.backup
sed -i '/"onscan\.js":/d' package.json

# For HRMS
cd ~/hrms-bench/apps/hrms
cp package.json package.json.backup
sed -i '/"html2canvas":/d' package.json

# Retry yarn install
yarn install --offline --check-files
```

## 🗄️ Database Issues

### Issue #7: MariaDB Connection Failed
**Symptoms:**
```
ERROR 1045 (28000): Access denied for user 'root'@'localhost'
```

**Root Cause:** MariaDB root password not set correctly

**Solutions:**
```bash
# Reset MariaDB root password
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"

# Alternative method
sudo mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root'); FLUSH PRIVILEGES;"

# Test connection
mysql -u root -proot -e "SELECT 'Connection successful';"

# If still failing, check MariaDB status
sudo systemctl status mariadb
sudo systemctl restart mariadb
```

### Issue #8: Site Creation Fails
**Symptoms:**
```
Database creation failed
```

**Solutions:**
```bash
# Check MariaDB is running
sudo systemctl status mariadb

# Verify database permissions
mysql -u root -proot -e "SHOW GRANTS FOR 'root'@'localhost';"

# Create site with explicit parameters
bench new-site mysite.local \
  --admin-password admin \
  --mariadb-root-password root \
  --force

# Check site creation
ls sites/
# Should show mysite.local directory
```

## 🌐 Web Interface Issues

### Issue #9: Cannot Access Web Interface
**Symptoms:**
- Browser shows "This site can't be reached"
- Connection refused errors

**Solutions:**
```bash
# Check if bench is running
ps aux | grep bench
# Should show bench processes

# Start bench if not running
cd ~/hrms-bench
bench start

# Check port availability
netstat -tlnp | grep :8000
# Should show bench process on port 8000

# Test local connection
curl -I http://localhost:8000
# Should return HTTP/1.1 200 OK

# Check firewall
sudo ufw status
# Ensure port 8000 is allowed
```

### Issue #10: Login Issues
**Symptoms:**
- Invalid credentials error
- Cannot access administrator account

**Solutions:**
```bash
# Reset administrator password
cd ~/hrms-bench
bench --site mysite.local set-admin-password admin

# Check user exists
bench --site mysite.local console
# In console: frappe.get_doc("User", "administrator")

# Create new administrator if needed
bench --site mysite.local add-user admin@example.com --first-name Admin --last-name User
bench --site mysite.local set-user-password admin@example.com admin
```

## 🔧 System Service Issues

### Issue #11: Redis Connection Failed
**Symptoms:**
```
redis.exceptions.ConnectionError: Error 111 connecting to localhost:6379
```

**Solutions:**
```bash
# Check Redis status
sudo systemctl status redis-server

# Start Redis if stopped
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Test Redis connection
redis-cli ping
# Expected: PONG

# Check Redis configuration
sudo cat /etc/redis/redis.conf | grep bind
# Should allow localhost connections
```

### Issue #12: Nginx Configuration Issues
**Symptoms:**
- 502 Bad Gateway errors
- Nginx not serving static files

**Solutions:**
```bash
# Check Nginx status
sudo systemctl status nginx

# Generate Nginx configuration
cd ~/hrms-bench
bench setup nginx

# Reload Nginx
sudo systemctl reload nginx

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## 📊 Performance Issues

### Issue #13: Slow Installation
**Symptoms:**
- Installation takes longer than expected
- System becomes unresponsive

**Solutions:**
```bash
# Check system resources
top
free -h
df -h

# Increase Node.js memory limit
export NODE_OPTIONS="--max_old_space_size=4096"

# Monitor disk I/O
iostat -x 1

# Close unnecessary applications
# Ensure sufficient RAM available
```

### Issue #14: Asset Building Timeout
**Symptoms:**
- Frontend build process hangs
- JavaScript compilation errors

**Solutions:**
```bash
# Increase build timeout
cd ~/hrms-bench
export NODE_OPTIONS="--max_old_space_size=4096"

# Build assets manually
bench build --app frappe
bench build --app erpnext
bench build --app hrms

# Check build logs
tail -f logs/bench.log
```

## 🔍 Diagnostic Commands

### System Information
```bash
# Check system details
uname -a
lsb_release -a
free -h
df -h

# Check installed packages
dpkg -l | grep -E "(mariadb|redis|nginx|python3)"

# Check running services
sudo systemctl list-units --type=service --state=running | grep -E "(mariadb|redis|nginx)"
```

### Bench Diagnostics
```bash
cd ~/hrms-bench

# Check bench status
bench --version
bench status

# Check site status
bench --site mysite.local list-apps
bench --site mysite.local migrate

# Check logs
tail -f logs/bench.log
tail -f logs/web.log
```

### Network Diagnostics
```bash
# Check port usage
netstat -tlnp | grep -E "(8000|11000|13000|3306|6379)"

# Test local connections
curl -I http://localhost:8000
telnet localhost 3306
redis-cli ping
```

## 🆘 Getting Help

### Log Collection
```bash
# Collect installation logs
cd ~/hrms-v15-offline-bundle
mkdir -p debug-logs

# Copy relevant logs
cp ~/hrms-bench/logs/* debug-logs/ 2>/dev/null || echo "No bench logs"
sudo cp /var/log/nginx/error.log debug-logs/ 2>/dev/null || echo "No nginx logs"
sudo cp /var/log/mysql/error.log debug-logs/ 2>/dev/null || echo "No mysql logs"

# System information
uname -a > debug-logs/system-info.txt
free -h >> debug-logs/system-info.txt
df -h >> debug-logs/system-info.txt

# Create debug archive
tar -czf debug-logs.tar.gz debug-logs/
```

### Support Channels
1. **GitHub Issues**: Report bugs with debug logs
2. **Frappe Community**: General HRMS questions
3. **Documentation**: Check official Frappe docs
4. **Professional Support**: Contact Frappe Technologies

---

**Remember**: Most issues are resolved by ensuring proper offline configuration and sufficient system resources.

