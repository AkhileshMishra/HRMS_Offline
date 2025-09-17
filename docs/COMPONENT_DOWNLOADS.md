# Component Download Guide

This guide explains how to download and use the individual components of the HRMS v15 offline bundle.

## 📦 **Download Options**

### **Option 1: Complete Bundle (Recommended)**
```bash
# Single download - everything included
wget "https://files.manuscdn.com/user_upload_by_module/session_file/95768430/OlfIHolYstwnrWsN.gz" -O hrms-v15-complete.tar.gz
```
- **Size**: 781 MB
- **Includes**: All components in one file
- **Best for**: Most users, production deployments

### **Option 2: Individual Components**
Download only the components you need:

#### **Small Components (GitHub Repository)**
```bash
# Frappe Framework (91M)
wget https://github.com/AkhileshMishra/HRMS_Offline/raw/master/releases/hrms-v15-frappe.tar.gz

# ERPNext (34M)
wget https://github.com/AkhileshMishra/HRMS_Offline/raw/master/releases/hrms-v15-erpnext.tar.gz

# Payments (122K)
wget https://github.com/AkhileshMishra/HRMS_Offline/raw/master/releases/hrms-v15-payments.tar.gz

# Tools & Configs (25M)
wget https://github.com/AkhileshMishra/HRMS_Offline/raw/master/releases/hrms-v15-tools.tar.gz
```

#### **Large Components (External Hosting)**
```bash
# HRMS Application (131M) - External link required
# System Packages (124M) - External link required  
# NPM Packages (183M) - External link required
# Python Wheels (189M) - External link required
```

## 🔧 **Assembly Instructions**

### **From Individual Components**
```bash
# 1. Create bundle directory
mkdir -p hrms-offline-bundle

# 2. Extract small components
tar -xzf hrms-v15-frappe.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-erpnext.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-payments.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-tools.tar.gz -C hrms-offline-bundle/

# 3. Extract large components (when available)
tar -xzf hrms-v15-hrms.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-debs.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-npm.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-wheels.tar.gz -C hrms-offline-bundle/

# 4. Verify structure
ls -la hrms-offline-bundle/
# Should show: repos/, wheels/, npm-offline/, debs/, tools/, configs/, docs/

# 5. Create complete bundle
tar -czf hrms-offline-bundle-assembled.tar.gz hrms-offline-bundle/
```

### **Partial Assembly (Development)**
```bash
# For development/testing with minimal components
mkdir -p hrms-offline-bundle

# Essential components only
tar -xzf hrms-v15-frappe.tar.gz -C hrms-offline-bundle/
tar -xzf hrms-v15-tools.tar.gz -C hrms-offline-bundle/

# Use with internet access for missing components
```

## 📊 **Component Matrix**

| Component | Size | Required | Purpose |
|-----------|------|----------|---------|
| **Frappe** | 91M | ✅ Essential | Core framework |
| **ERPNext** | 34M | ✅ Essential | Business modules |
| **HRMS** | 131M | ✅ Essential | HR functionality |
| **Payments** | 122K | ⚪ Optional | Payment processing |
| **Wheels** | 189M | ✅ Essential | Python dependencies |
| **NPM** | 183M | ✅ Essential | Frontend dependencies |
| **Debs** | 124M | ✅ Essential | System packages |
| **Tools** | 25M | ✅ Essential | Installation tools |

## 🎯 **Use Cases**

### **Complete Offline Installation**
- **Components Needed**: All 8 components
- **Total Size**: 777M
- **Use Case**: Production deployment, air-gapped environments

### **Development Setup**
- **Components Needed**: Frappe + ERPNext + HRMS + Tools
- **Total Size**: ~281M
- **Use Case**: Development with internet access for dependencies

### **Minimal Testing**
- **Components Needed**: Frappe + Tools
- **Total Size**: ~116M
- **Use Case**: Framework testing, development environment

### **Custom Deployment**
- **Components Needed**: Selected based on requirements
- **Total Size**: Variable
- **Use Case**: Specific feature testing, custom installations

## 🔍 **Verification**

### **Component Integrity**
```bash
# Check extracted structure
find hrms-offline-bundle -type d -maxdepth 1
# Expected: repos, wheels, npm-offline, debs, tools, configs, docs

# Verify application count
ls hrms-offline-bundle/repos/
# Expected: frappe, erpnext, hrms, payments

# Check package counts
ls hrms-offline-bundle/wheels/ | wc -l
# Expected: ~172 files

ls hrms-offline-bundle/npm-offline/ | wc -l  
# Expected: ~820 files

ls hrms-offline-bundle/debs/ | wc -l
# Expected: ~161 files
```

### **Installation Test**
```bash
# Test with assembled bundle
./install-offline-final.sh --bundle-tar hrms-offline-bundle-assembled.tar.gz --site-name test.local

# Verify installation
bench --version
bench --site test.local list-apps
```

## 🚨 **Troubleshooting**

### **Missing Components**
```bash
# Error: Component not found
# Solution: Verify all required components are downloaded and extracted

# Check for missing directories
ls -la hrms-offline-bundle/
```

### **Size Mismatches**
```bash
# Error: Archive appears corrupted
# Solution: Re-download component and verify size

# Check component sizes
ls -lh hrms-v15-*.tar.gz
```

### **Assembly Failures**
```bash
# Error: Cannot create bundle
# Solution: Ensure sufficient disk space and permissions

# Check disk space
df -h .

# Check permissions
ls -la hrms-offline-bundle/
```

## 📝 **Best Practices**

1. **Verify Downloads**: Check file sizes match expected values
2. **Test Assembly**: Verify bundle structure before installation
3. **Backup Components**: Keep individual components for future use
4. **Document Versions**: Track which components are used together
5. **Clean Extraction**: Use clean directories for assembly

## 🔗 **External Resources**

- **Complete Bundle**: [Direct Download Link]
- **GitHub Repository**: https://github.com/AkhileshMishra/HRMS_Offline
- **Installation Guide**: [docs/INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **Troubleshooting**: [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Note**: Component-based installation is more complex than using the complete bundle. Use the complete bundle unless you have specific requirements for individual components.

