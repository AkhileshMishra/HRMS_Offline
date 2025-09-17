# HRMS v15 Component Releases

This directory contains the component archives that make up the complete HRMS v15 offline bundle.

## 📦 Available Components (GitHub Repository)

### ✅ **Included in Repository** (Under 100MB)

| Component | Size | Description |
|-----------|------|-------------|
| **hrms-v15-frappe.tar.gz** | 91M | Frappe Framework v15.81.0 source code |
| **hrms-v15-erpnext.tar.gz** | 34M | ERPNext v15.78.1 source code |
| **hrms-v15-payments.tar.gz** | 122K | Payments v0.0.1 source code |
| **hrms-v15-tools.tar.gz** | 25M | Development tools, configs, and documentation |

### ❌ **External Hosting Required** (Over 100MB)

| Component | Size | Description | Download Link |
|-----------|------|-------------|---------------|
| **hrms-v15-hrms.tar.gz** | 131M | HRMS v15.49.2 source code | [External Link Required] |
| **hrms-v15-debs.tar.gz** | 124M | System packages (161 .deb files) | [External Link Required] |
| **hrms-v15-npm.tar.gz** | 183M | NPM packages (820+ packages) | [External Link Required] |
| **hrms-v15-wheels.tar.gz** | 189M | Python packages (172 wheels) | [External Link Required] |

## 🚀 **Usage Instructions**

### **Option 1: Use Complete Bundle (Recommended)**
```bash
# Download the complete 781MB bundle
wget "https://files.manuscdn.com/user_upload_by_module/session_file/95768430/OlfIHolYstwnrWsN.gz" -O hrms-v15-complete-offline.tar.gz

# Use with installer
./install-offline-final.sh --bundle-tar hrms-v15-complete-offline.tar.gz --site-name mysite.local
```

### **Option 2: Assemble from Components**
```bash
# Create bundle directory
mkdir -p hrms-offline-bundle

# Extract repository components
tar -xzf hrms-v15-frappe.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-erpnext.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-payments.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-tools.tar.gz -C hrms-offline-bundle/

# Download and extract large components (when available)
# tar -xzf hrms-v15-hrms.tar.gz -C hrms-offline-bundle/
# tar -xzf hrms-v15-debs.tar.gz -C hrms-offline-bundle/
# tar -xzf hrms-v15-npm.tar.gz -C hrms-offline-bundle/
# tar -xzf hrms-v15-wheels.tar.gz -C hrms-offline-bundle/

# Create complete bundle
tar -czf hrms-offline-bundle-assembled.tar.gz hrms-offline-bundle/
```

## 📊 **Component Details**

### **hrms-v15-frappe.tar.gz** (91M)
- **Contents**: Frappe Framework source code
- **Version**: v15.81.0
- **Commit**: 1c9ae01384762d809e5a05662d999eda2adc6cb8
- **Includes**: Core framework, web interface, database abstraction

### **hrms-v15-erpnext.tar.gz** (34M)
- **Contents**: ERPNext application source code
- **Version**: v15.78.1
- **Commit**: ceb17b6b614d64ad3369dec9f24e9747176b620a
- **Includes**: Business management modules, accounting, inventory

### **hrms-v15-payments.tar.gz** (122K)
- **Contents**: Payments application source code
- **Version**: v0.0.1
- **Commit**: a682448a63d59ecf9288cfafa29cdad215ddf0ff
- **Includes**: Payment processing integration

### **hrms-v15-tools.tar.gz** (25M)
- **Contents**: Development tools and configurations
- **Includes**:
  - Node.js v18.20.4 tarball
  - Yarn v1.22.19 standalone
  - MariaDB charset configuration
  - Pip offline configuration templates
  - Version documentation

## 🔧 **Large Component Alternatives**

### **For hrms-v15-hrms.tar.gz** (131M)
```bash
# Alternative: Clone directly (requires internet)
git clone https://github.com/frappe/hrms.git --branch version-15 --depth 1
```

### **For hrms-v15-wheels.tar.gz** (189M)
```bash
# Alternative: Download Python packages (requires internet)
pip download -d wheels/ -r requirements.txt
```

### **For hrms-v15-npm.tar.gz** (183M)
```bash
# Alternative: Create NPM offline mirror (requires internet)
yarn install --offline-mirror npm-offline/
```

### **For hrms-v15-debs.tar.gz** (124M)
```bash
# Alternative: Download system packages (requires internet)
sudo apt-get --download-only install [package-list]
```

## 📝 **Notes**

1. **GitHub Limitations**: Files over 100MB cannot be stored in GitHub repositories
2. **Complete Bundle**: For full offline capability, use the complete bundle from external hosting
3. **Component Assembly**: Individual components can be assembled but require careful extraction
4. **Version Consistency**: All components are from the same bundle creation session for compatibility

## 🆘 **Support**

- **Issues**: Report problems via GitHub Issues
- **Documentation**: See main repository documentation
- **Community**: Frappe community forums

---

**Last Updated**: September 17, 2024
**Bundle Version**: v1.0.0
**Total Component Size**: 777M (when all components combined)

