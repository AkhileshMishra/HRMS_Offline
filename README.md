# HRMS v15 Offline Bundle

A complete offline installation package for **Frappe HRMS v15** that enables air-gapped deployment without internet access.

## 🎯 Overview

This repository provides a comprehensive solution for installing Frappe HRMS v15 in completely offline environments. The bundle includes all necessary components:

- **4 Applications**: Frappe Framework, ERPNext, HRMS, and Payments
- **172 Python Wheels**: All dependencies including build tools
- **820+ NPM Packages**: Complete frontend dependency mirror
- **161 System Packages**: Ubuntu 22.04 .deb files with local repository
- **Development Tools**: Node.js v18.20.4 and Yarn v1.22.19

## 📦 What's Included

### Core Applications
- **Frappe Framework v15.81.0** - Base platform
- **ERPNext v15.78.1** - Business management system
- **HRMS v15.49.2** - Human resource management
- **Payments v0.0.1** - Payment processing integration

### Dependencies
- **Python Environment**: 172 wheels including bootstrap packages (pip, wheel, setuptools)
- **Build Dependencies**: flit_core, editables, tomli for modern Python packaging
- **Frontend Dependencies**: Complete Yarn v1 offline mirror with 820+ packages
- **System Packages**: 161 Ubuntu 22.04 .deb files with local APT repository

### Tools & Configurations
- **Node.js v18.20.4**: JavaScript runtime
- **Yarn v1.22.19**: Package manager for frontend dependencies
- **MariaDB Configuration**: UTF8MB4 charset setup
- **Offline pip Configuration**: No-index setup for air-gapped installation

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04 LTS (recommended)
- 4GB+ RAM
- 10GB+ free disk space
- No internet access required after download

### Installation

1. **Download the bundle and installer:**
```bash
# Download complete bundle (781 MB)
wget "https://files.manuscdn.com/user_upload_by_module/session_file/95768430/OlfIHolYstwnrWsN.gz" -O hrms-v15-complete-offline.tar.gz

# Download installer script
wget "https://files.manuscdn.com/user_upload_by_module/session_file/95768430/GZLoOltGJSimFTWv.sh" -O install-offline-final.sh
```

2. **Run the installation:**
```bash
# Make installer executable
chmod +x install-offline-final.sh

# Set environment variables
export DB_ROOT_PWD="root"
export ADMIN_PWD="admin"

# Install with all apps
sudo -E ./install-offline-final.sh \
  --bundle-tar ./hrms-v15-complete-offline.tar.gz \
  --with-payments \
  --site-name mysite.local
```

3. **Access your HRMS system:**
```bash
# Navigate to bench directory
cd ~/hrms-bench

# Start the server
bench start

# Access in browser: http://localhost:8000
# Login: administrator / admin
```

## 📋 Installation Options

### Basic Installation
```bash
sudo -E ./install-offline-final.sh --bundle-tar ./hrms-v15-complete-offline.tar.gz --site-name mysite.local
```

### With All Apps
```bash
sudo -E ./install-offline-final.sh --bundle-tar ./hrms-v15-complete-offline.tar.gz --with-payments --site-name mysite.local
```

### Production Setup
```bash
sudo -E ./install-offline-final.sh --bundle-tar ./hrms-v15-complete-offline.tar.gz --with-payments --production --site-name mysite.local
```

## 🔧 Advanced Configuration

### Custom Installation Paths
```bash
sudo -E ./install-offline-final.sh \
  --bundle-tar ./hrms-v15-complete-offline.tar.gz \
  --bench-home /opt/hrms-bench \
  --site-name production.local \
  --with-payments
```

### Environment Variables
```bash
export DB_ROOT_PWD="your_db_password"
export ADMIN_PWD="your_admin_password"
export BENCH_HOME="/custom/path/to/bench"
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Installation Fails at Line 75
**Solution**: Check disk space and permissions
```bash
df -h .
sudo chown -R $USER:$USER /opt/hrms-offline
```

#### 2. Yarn Network Errors
**Solution**: Ensure offline configuration is applied
```bash
yarn config set yarn-offline-mirror "/path/to/npm-offline"
yarn config set network-timeout 1
```

#### 3. Missing Dependencies
**Solution**: Check if all wheels are present
```bash
ls /path/to/bundle/wheels/ | wc -l  # Should show 172
```

#### 4. MariaDB Connection Issues
**Solution**: Reset MariaDB root password
```bash
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"
```

### Known Limitations

1. **Missing NPM Packages**: Some optional packages (onscan.js, html2canvas) are not included
   - **Workaround**: Temporarily removed from package.json during installation
   - **Impact**: Barcode scanning and HTML-to-canvas features may not work

2. **Subdirectory Dependencies**: HRMS roster subdirectory may require additional configuration
   - **Workaround**: Manual yarn configuration for subdirectories

## 📊 Bundle Statistics

| Component | Count | Size |
|-----------|-------|------|
| Python Wheels | 172 | ~200MB |
| NPM Packages | 820+ | ~186MB |
| System Packages | 161 | ~300MB |
| Source Repositories | 4 | ~50MB |
| Tools & Configs | - | ~45MB |
| **Total Bundle** | - | **781MB** |

## 🔍 Verification

### Check Installation
```bash
# Verify bench installation
bench --version  # Should show 5.25.9

# Check installed apps
bench --site mysite.local list-apps

# Verify services
sudo systemctl status mariadb redis-server
```

### Test Functionality
```bash
# Start development server
bench start

# Access in browser
curl http://localhost:8000

# Check HRMS modules
# Navigate to: http://localhost:8000/app
# Look for HR and Payroll modules in sidebar
```

## 🤝 Contributing

### Reporting Issues
1. Check existing issues in the repository
2. Provide detailed error logs and system information
3. Include steps to reproduce the problem

### Improving the Bundle
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## 📄 License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Frappe Technologies** for the excellent Frappe Framework and ERPNext
- **HRMS Contributors** for the comprehensive HR management system
- **Community** for testing and feedback

## 📞 Support

- **Documentation**: Check the `docs/` directory for detailed guides
- **Issues**: Report problems via GitHub Issues
- **Community**: Join the Frappe community forums

---

**Note**: This is an unofficial offline bundle. For official support, please contact Frappe Technologies.

