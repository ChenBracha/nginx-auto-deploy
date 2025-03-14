# 🚀 NGINX Auto Deploy

## 👥 Authors

- [Chen Bracha](https://github.com/ChenBracha)
- [Vetrigo](https://github.com/vetrigo)

## 📄 Overview

This script is a powerful tool for configuring and managing **NGINX** with various options. It allows users to set up a complete NGINX configuration with properly nested `server` and `location` directives. The script can also check for the presence of NGINX and install it if necessary.

## 🌟 Features

- 🌐 **Virtual host configuration**
- 🏠 **User directory support**
- 🔒 **Basic HTTP authentication**
- 🔐 **PAM authentication**
- 🖥️ **CGI scripting support**
- 🛠️ **Dependency checks and installation**

---

## 🛠️ Installation

### 1️⃣ **Clone the Repository**

```bash
git clone git@github.com:ChenBracha/nginx-auto-deploy.git
cd nginx-auto-deploy
```

### 2️⃣ **Run the Script**

```bash
chmod +x nginx-setup.sh
./nginx-setup.sh
```

---

## ⚙️ Usage

When the script runs, it presents an interactive menu:

```bash
Select an option:
1. Configure a new host
2. Configure UserDir
3. Configure Basic Authentication
4. Configure PAM Authentication
5. Backup NGINX Configuration
6. Exit
```

Choose an option to configure the desired NGINX feature.

### 🏠 Configure a New Host
This option allows you to create a virtual host configuration and add it to NGINX.

### 📂 Configure UserDir
This option enables the `~/public_html/` directory for users to host web content.

### 🔒 Configure Basic Authentication
This secures a specific location in NGINX using `htpasswd`-based authentication.

### 🔐 Configure PAM Authentication
This integrates PAM (Pluggable Authentication Modules) to authenticate system users.

### 🛠️ Backup NGINX Configuration
This feature automatically backs up the current `nginx.conf` and site configurations before modifications.

### 🚀 Exiting
Use this option to exit the script safely.

---

## 📋 Requirements

```yaml
- 🛠 Ubuntu or Debian-based system
- 🌐 NGINX installed
- 🔑 apache2-utils (for Basic Authentication)
- 🔐 libpam0g-dev and libpam-modules (for PAM Authentication)
```

---

## ✅ Task List

```yaml
- [x] Check if NGINX is installed
- [x] Check if a virtual host exists, and prompt user if missing
- [x] Install dependencies for UserDir, Authentication, and CGI support
- [x] Provide an argument-based system for installation & configuration
- [x] Automate backup of NGINX configurations
```

---

## 🤝 Contributing

This project was developed by **Chen Bracha** and **Vetrigo**. 

Contributions are welcome! Feel free to **open an issue** or **submit a pull request**.

---

## 📜 License

This project is licensed under the **MIT License**.

---

## 🔗 Reference

For further details, check the [Vaiolabs NGINX Shallow Dive](https://gitlab.com/vaiolabs-io/nginx-shallow-dive).
