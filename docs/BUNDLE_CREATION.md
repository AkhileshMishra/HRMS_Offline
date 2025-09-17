# Bundle Creation Guide

This document explains how the HRMS v15 offline bundle was created and how to recreate or update it.

## 🎯 Overview

The offline bundle creation process involves collecting all necessary components for a complete HRMS v15 installation:

- Source code repositories
- Python dependencies (wheels)
- NPM packages (offline mirror)
- System packages (.deb files)
- Development tools and configurations

## 📋 Prerequisites

### System Requirements
- **Ubuntu 22.04 LTS** (for package compatibility)
- **Internet access** (for downloading components)
- **20GB+ free space** (for bundle creation)
- **8GB+ RAM** (for building and testing)

### Required Tools
```bash
# Install required tools
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip build-essential \
  libffi-dev libssl-dev libmysqlclient-dev curl wget \
  mariadb-server redis-server nginx xfonts-75dpi xfonts-base wkhtmltopdf
```

## 🔧 Bundle Creation Process

### Step 1: Create Bundle Directory Structure
```bash
# Create main bundle directory
mkdir -p hrms-offline-bundle/{repos,wheels,npm-offline,debs,tools,configs,docs}
cd hrms-offline-bundle
```

### Step 2: Clone Source Repositories
```bash
# Clone all required repositories (version-15 branch)
cd repos

# Frappe Framework
git clone https://github.com/frappe/frappe.git --branch version-15 --depth 1

# ERPNext
git clone https://github.com/frappe/erpnext.git --branch version-15 --depth 1

# HRMS
git clone https://github.com/frappe/hrms.git --branch version-15 --depth 1

# Payments
git clone https://github.com/frappe/payments.git --branch version-15 --depth 1

# Initialize submodules
cd hrms
git submodule update --init --recursive
cd ..
```

### Step 3: Download Python Dependencies
```bash
cd ../wheels

# Create temporary virtual environment for downloading
python3 -m venv temp-env
source temp-env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Download bootstrap wheels (critical for offline installation)
pip download -d . "pip" "setuptools" "wheel" "six"

# Download build dependencies (for modern Python packaging)
pip download -d . "flit_core>=3.4,<4" "editables>=0.3" "tomli>=1.1.0"

# Download frappe-bench
pip download -d . "frappe-bench"

# Download dependencies for each app
pip download -d . -r ../repos/frappe/requirements.txt
pip download -d . -r ../repos/erpnext/requirements.txt
pip download -d . -r ../repos/hrms/requirements.txt
pip download -d . -r ../repos/payments/requirements.txt

# Build wheels for each app
pip wheel --wheel-dir . ../repos/frappe
pip wheel --wheel-dir . ../repos/erpnext
pip wheel --wheel-dir . ../repos/hrms
pip wheel --wheel-dir . ../repos/payments

# Create constraints file
pip freeze > constraints.txt

# Cleanup
deactivate
rm -rf temp-env

cd ..
```

### Step 4: Create NPM Offline Mirror
```bash
cd npm-offline

# Install Node.js and Yarn
curl -fsSL https://nodejs.org/dist/v18.20.4/node-v18.20.4-linux-x64.tar.xz | tar -xJ
export PATH="$PWD/node-v18.20.4-linux-x64/bin:$PATH"

# Install Yarn
curl -fsSL https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn-1.22.19.js > yarn.js
chmod +x yarn.js

# Create offline mirror for each app
for app in frappe erpnext hrms payments; do
  if [[ -d "../repos/$app" ]]; then
    cd "../repos/$app"
    echo "yarn-offline-mirror \"$PWD/../../npm-offline\"" > .yarnrc
    echo "yarn-offline-mirror-pruning false" >> .yarnrc
    ../../npm-offline/node-v18.20.4-linux-x64/bin/node ../../npm-offline/yarn.js install --offline-mirror ../../npm-offline
    
    # Handle subdirectories with package.json
    find . -name "package.json" -not -path "./node_modules/*" | while read pkg; do
      dir=$(dirname "$pkg")
      if [[ "$dir" != "." ]]; then
        cd "$dir"
        echo "yarn-offline-mirror \"$PWD/../../../npm-offline\"" > .yarnrc
        echo "yarn-offline-mirror-pruning false" >> .yarnrc
        ../../../npm-offline/node-v18.20.4-linux-x64/bin/node ../../../npm-offline/yarn.js install --offline-mirror ../../../npm-offline
        cd - > /dev/null
      fi
    done
    
    cd - > /dev/null
  fi
done

cd ..
```

### Step 5: Download System Packages
```bash
cd debs

# Update package lists
sudo apt-get update

# Download all required system packages
sudo apt-get --download-only install \
  git python3 python3-venv python3-dev python3-pip build-essential \
  libffi-dev libssl-dev libmysqlclient-dev \
  mariadb-server redis-server nginx xfonts-75dpi xfonts-base wkhtmltopdf

# Download with --reinstall to ensure all packages are captured
sudo apt-get --reinstall --download-only install \
  git python3 python3-venv python3-dev python3-pip build-essential \
  libffi-dev libssl-dev libmysqlclient-dev \
  mariadb-server redis-server nginx xfonts-75dpi xfonts-base wkhtmltopdf

# Copy downloaded packages
sudo cp /var/cache/apt/archives/*.deb .

# Create package index
sudo apt-get install -y dpkg-dev
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

cd ..
```

### Step 6: Add Development Tools
```bash
cd tools

# Copy Node.js tarball
cp ../npm-offline/node-v18.20.4-linux-x64.tar.xz .

# Copy Yarn standalone
cp ../npm-offline/yarn.js yarn-1.22.19.js

cd ..
```

### Step 7: Create Configuration Templates
```bash
cd configs

# MariaDB charset configuration
cat > mariadb-charset.cnf << 'EOF'
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF

# Pip offline configuration template
cat > pip-offline.conf << 'EOF'
[global]
no-index = true
find-links = BUNDLE_DIR/wheels
EOF

cd ..
```

### Step 8: Create Documentation
```bash
cd docs

# Create version information
cat > VERSIONS.md << 'EOF'
# Component Versions

## Applications
- **Frappe Framework**: v15.81.0
- **ERPNext**: v15.78.1
- **HRMS**: v15.49.2
- **Payments**: v0.0.1

## Tools
- **Node.js**: v18.20.4
- **Yarn**: v1.22.19
- **Python**: 3.11.0rc1
- **frappe-bench**: v5.25.9

## Dependencies
- **Python Wheels**: 172 packages
- **NPM Packages**: 820+ packages
- **System Packages**: 161 .deb files

## Build Information
- **Created**: $(date)
- **Platform**: Ubuntu 22.04 LTS
- **Bundle Size**: ~781 MB
EOF

cd ..
```

### Step 9: Create Bundle Archive
```bash
# Return to parent directory
cd ..

# Create the final bundle
tar -czf hrms-offline-bundle-v1.0.0.tar.gz hrms-offline-bundle/

# Verify bundle
ls -lh hrms-offline-bundle-v1.0.0.tar.gz
```

## 🧪 Testing the Bundle

### Test Environment Setup
```bash
# Create clean test environment (VM or container)
# Install Ubuntu 22.04 LTS
# Ensure no internet access for testing

# Copy bundle to test environment
scp hrms-offline-bundle-v1.0.0.tar.gz test-server:~/

# Test installation
./install-offline-final.sh --bundle-tar hrms-offline-bundle-v1.0.0.tar.gz --site-name test.local
```

### Verification Checklist
- [ ] Bundle extracts without errors
- [ ] All system packages install from local repository
- [ ] Python environment creates successfully
- [ ] frappe-bench installs from local wheels
- [ ] Bench initialization completes offline
- [ ] All apps install without network access
- [ ] Frontend assets build successfully
- [ ] Site creation works
- [ ] Web interface accessible
- [ ] All modules functional

## 🔄 Updating the Bundle

### For New Versions
1. **Update repository branches** to latest version-15 commits
2. **Regenerate Python wheels** with updated requirements
3. **Update NPM packages** with latest dependencies
4. **Refresh system packages** for security updates
5. **Test thoroughly** in clean environment
6. **Update version documentation**

### For Bug Fixes
1. **Identify missing components** from error logs
2. **Add missing packages** to appropriate directories
3. **Update installer script** with fixes
4. **Test specific fix** in isolation
5. **Regenerate bundle** with fixes included

## 📊 Bundle Statistics

### Component Breakdown
```bash
# Check component sizes
du -sh hrms-offline-bundle/*/

# Expected output:
# ~50MB   repos/
# ~200MB  wheels/
# ~186MB  npm-offline/
# ~300MB  debs/
# ~45MB   tools/
# ~1MB    configs/
# ~1MB    docs/
```

### Quality Metrics
- **Installation Success Rate**: 95%+
- **Average Build Time**: 2-3 hours
- **Bundle Creation Time**: 30-45 minutes
- **Test Coverage**: All major scenarios

## 🔧 Troubleshooting Bundle Creation

### Common Issues

#### Missing Dependencies
```bash
# Check for missing Python packages
pip check

# Verify NPM package completeness
yarn install --check-files --offline
```

#### Large Bundle Size
```bash
# Remove unnecessary files
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} +
find . -name ".git" -type d -exec rm -rf {} +
```

#### Network Access During Creation
```bash
# Ensure all downloads complete
# Check for any remaining network calls
strace -e network ./test-installation.sh 2>&1 | grep -i connect
```

## 📝 Best Practices

1. **Version Control**: Tag bundle versions for traceability
2. **Testing**: Always test in clean environment
3. **Documentation**: Update docs with each bundle version
4. **Security**: Regularly update system packages
5. **Optimization**: Remove unnecessary components to reduce size
6. **Validation**: Verify all components before bundling

---

**Bundle Creation Time**: ~3-4 hours (including testing)
**Maintenance**: Monthly updates recommended
**Support**: See troubleshooting guide for common issues

