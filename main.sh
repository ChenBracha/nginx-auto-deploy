#!/usr/bin/env bash
#######################
# Date:14/03/2025 (D/M/Y) 
# Developers: ChenBracha & Leon Avetisian
# Version: 0.0.10
# Description: Create a shell script to automate the setup of **UserDir, Authentication (Basic & PAM)
# CGI scripting, and Virtual Hosts** in NGINX
# ensuring dependencies are installed and configurations are properly managed.
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

install_basic_auth_tools() {
    echo "Installing apache2-utils and nginx-extras..."
    sudo apt install -y apache2-utils nginx-extras
    echo "Installation completed."
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
    backup_nginx_config  # Backup before modifying the file

    # Create the /secure directory if it doesn't exist
    sudo mkdir -p /var/www/html/secure
    echo "<h1>Restricted Area</h1>" | sudo tee /var/www/html/secure/index.html > /dev/null
    sudo chown -R www-data:www-data /var/www/html/secure
    sudo chmod -R 755 /var/www/html/secure

    BASIC_AUTH_BLOCK=$(cat <<'EOF'
    location /secure {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        root /var/www/html;
        index index.html;
    }
EOF
)

    # Ensure the default site config exists
    if [ ! -f /etc/nginx/sites-available/default ]; then
        echo "Default site configuration not found! Creating it..."
        sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;
}
EOF
    fi

    # Ensure the Basic Auth block is inside the server block, under other locations
    if ! grep -q "location /secure" /etc/nginx/sites-available/default; then
        echo "Adding Basic Authentication configuration..."
        sudo sed -i '/index index.html;/a \n    location /secure {
        auth_basic "Restricted Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        root /var/www/html;
        index index.html;
    }' /etc/nginx/sites-available/default
    else
        echo "Basic Authentication configuration already exists."
    fi

    # Restart Nginx
    sudo nginx -t && sudo systemctl restart nginx
    echo "Basic Authentication has been configured and is now available at /secure."
}

configure_pam_auth() {
    echo "Configuring PAM Authentication in Nginx..."
    backup_nginx_config  # Backup before modifying the file

    # Install PAM dependencies
    sudo apt install -y libpam0g-dev libpam-modules

    # Create PAM configuration file for Nginx
    sudo tee /etc/pam.d/nginx > /dev/null <<EOF
auth       include      common-auth
account    include      common-account
EOF

    # Grant Nginx access to the system authentication files
    sudo usermod -aG shadow www-data

    # Create the /auth-pam directory and test page
    sudo mkdir -p /var/www/html/auth-pam
    echo "<html><body><div style='width: 100%; font-size: 40px; font-weight: bold; text-align: center;'>Test Page for PAM Auth</div></body></html>" | sudo tee /var/www/html/auth-pam/index.html > /dev/null
    sudo chown -R www-data:www-data /var/www/html/auth-pam
    sudo chmod -R 755 /var/www/html/auth-pam

    PAM_AUTH_BLOCK=$(cat <<'EOF'
    location /auth-pam {
        auth_pam "PAM Authentication";
        auth_pam_service_name "nginx";
        root /var/www/html;
        index index.html;
    }
EOF
)

    # Ensure the PAM Auth block is inside the server block
    if ! grep -q "location /auth-pam" /etc/nginx/sites-available/default; then
        echo "Adding PAM Authentication configuration..."
        sudo sed -i '/index index.html;/a \n    location /auth-pam {
        auth_pam "PAM Authentication";
        auth_pam_service_name "nginx";
        root /var/www/html;
        index index.html;
    }' /etc/nginx/sites-available/default
    else
        echo "PAM Authentication configuration already exists."
    fi

    # Restart Nginx
    sudo nginx -t && sudo systemctl restart nginx
    echo "PAM Authentication has been configured and is now available at /auth-pam."
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

# Run the functions
if check_os_and_nginx; then
    show_menu
fi
