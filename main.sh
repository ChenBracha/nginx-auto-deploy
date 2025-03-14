#!/usr/bin/env bash
#######################
# Date:14/03/2025 (D/M/Y) 
# Developers: ChenBracha & Leon Avetisian
# Version: 0.0.10
# Description: Create a shell script to automate the setup of **UserDir, Authentication (Basic & PAM),
# Virtual Hosts** in NGINX ensuring dependencies are installed and configurations are properly managed.
######################

check_os_and_nginx() {
    # Check if the OS is Ubuntu or Debian
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
            echo "This script is designed for Ubuntu or Debian only."
            return 1
        fi
        echo "OS is Ubuntu or Debian."
    else
        echo "OS release file not found. Unable to determine OS."
        return 1
    fi

    # Check if nginx is installed
    if ! command -v nginx &> /dev/null; then
        read -p "Nginx is not installed. Do you want to install it? (yes/no): " install_nginx
        if [[ "$install_nginx" =~ ^[Yy] ]]; then
            sudo apt update && sudo apt install -y nginx
            echo "Nginx has been installed."
        else
            echo "Nginx installation skipped."
            return 1
        fi
    else
        echo "Nginx is already installed."
    fi
    return 0
}

create_new_host() {
    echo "Creating a new virtual host..."
    read -p "Enter the domain name for the new host: " domain
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    sudo tee /etc/nginx/sites-available/$domain > /dev/null <<EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/$domain;
    index index.html;
}
EOF
    sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    sudo mkdir -p /var/www/$domain
    echo "<h1>Welcome to $domain</h1>" | sudo tee /var/www/$domain/index.html > /dev/null
    sudo systemctl restart nginx
    echo "Virtual host $domain has been created and enabled."
}

configure_user_dir() {
    echo "Configuring UserDir..."
    
    # Ask for username
    read -p "Enter the username for UserDir configuration: " username
    if [[ -z "$username" ]]; then
        echo "Username cannot be empty."
        return
    fi
    
    # Ensure Nginx configuration supports UserDir
    if ! grep -q "location ~ ^/~" /etc/nginx/sites-available/default; then
        echo "Adding UserDir configuration to Nginx..."
        sudo tee -a /etc/nginx/sites-available/default > /dev/null <<EOF
    location ~ ^/~(.+?)(/.*)?$ {
        alias /home/\$1/public_html\$2;
    }
EOF
    fi
    
    # Ensure public_html directory exists for the entered user
    if [ ! -d "/home/$username/public_html" ]; then
        sudo mkdir -p "/home/$username/public_html"
        sudo chmod 755 "/home/$username/public_html"
        sudo chown $username:$username "/home/$username/public_html"
    fi
    
    # Restart Nginx
    sudo systemctl restart nginx
    echo "✅ UserDir has been successfully configured in Nginx. Test with: http://localhost/~$username/"
}

install_basic_auth_tools() {
    echo "Installing Basic Authentication tools..."
    sudo apt install -y apache2-utils
}

create_basic_auth_user() {
    read -p "Enter username for Basic Authentication: " username
    if [[ -z "$username" ]]; then
        echo "Username cannot be empty."
        return
    fi
    sudo htpasswd -c /etc/nginx/.htpasswd "$username"
    echo "User $username has been created for Basic Authentication."
}

configure_basic_auth() {
    echo "Configuring Basic Authentication in Nginx..."
    sudo mkdir -p /var/www/html/secure
    echo "<h1>Restricted Area</h1>" | sudo tee /var/www/html/secure/index.html > /dev/null
    sudo chown -R www-data:www-data /var/www/html/secure
    sudo chmod -R 755 /var/www/html/secure
    sudo sed -i '/index index.html;/a \n    location /secure {\n        auth_basic "Restricted Area";\n        auth_basic_user_file /etc/nginx/.htpasswd;\n        root /var/www/html;\n        index index.html;\n    }' /etc/nginx/sites-available/default
    sudo nginx -t && sudo systemctl restart nginx
    echo "Basic Authentication has been configured and is now available at /secure."
}

configure_pam_auth() {
    echo "Configuring PAM Authentication in Nginx..."
    sudo apt install -y libpam0g-dev libpam-modules
    sudo tee /etc/pam.d/nginx > /dev/null <<EOF
auth       include      common-auth
account    include      common-account
EOF
    sudo usermod -aG shadow www-data
    echo "PAM Authentication has been configured."
}

show_menu() {
    while true; do
        echo -e  "\nSelect an option:"
        echo "1. Configure a new host"
        echo "2. Configure UserDir"
        echo "3. Configure Basic Authentication"
        echo "4. Configure PAM Authentication"
        echo "5. Exit"
        read -p "Enter your choice: " choice
        case $choice in
            1) create_new_host ;;
            2) configure_user_dir ;;
            3) install_basic_auth_tools && create_basic_auth_user && configure_basic_auth ;;
            4) configure_pam_auth ;;
            5) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

if check_os_and_nginx; then
    show_menu
fi
