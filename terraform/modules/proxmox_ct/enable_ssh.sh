#!/bin/bash

check_dns() {
    echo "Testing DNS connectivity..."
    while ! ping -c 1 -W 2 cloudflare.com >/dev/null 2>&1; do
        echo "DNS test failed. Retrying in 5 seconds..."
        sleep 5
    done
    echo "DNS connectivity is functional."
}

# Function to detect the package manager
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt-get"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unsupported"
    fi
}

# Function to install and enable SSH silently
install_and_enable_ssh() {
    package_manager=$(detect_package_manager)
    
    case "$package_manager" in
        apt-get)
            echo "Detected apt-get. Installing SSH..."
            DEBIAN_FRONTEND=noninteractive sudo apt-get update -y >/dev/null 2>&1
            DEBIAN_FRONTEND=noninteractive sudo apt-get install -y openssh-server >/dev/null 2>&1
            sudo systemctl enable ssh >/dev/null 2>&1
            sudo systemctl start ssh >/dev/null 2>&1
            ;;
        dnf)
            echo "Detected dnf. Installing SSH..."
            sudo dnf install -y openssh-server >/dev/null 2>&1
            sudo systemctl enable sshd >/dev/null 2>&1
            sudo systemctl start sshd >/dev/null 2>&1
            ;;
        pacman)
            echo "Detected pacman. Installing SSH..."
            sudo pacman -Sy --noconfirm openssh >/dev/null 2>&1
            sudo systemctl enable sshd >/dev/null 2>&1
            sudo systemctl start sshd >/dev/null 2>&1
            ;;
        zypper)
            echo "Detected zypper. Installing SSH..."
            sudo zypper refresh >/dev/null 2>&1
            sudo zypper --non-interactive install openssh >/dev/null 2>&1
            sudo systemctl enable sshd >/dev/null 2>&1
            sudo systemctl start sshd >/dev/null 2>&1
            ;;
        *)
            echo "Unsupported package manager: $package_manager" >&2
            exit 1
            ;;
    esac

    echo "SSH installed and enabled successfully using $package_manager."
}

check_dns
install_and_enable_ssh