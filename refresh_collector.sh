#!/bin/bash

# Function to check if a command succeeded
check_status() {
    if [ $? -ne 0 ]; then
        echo "Warning: $1 failed. Continuing with cleanup..."
        return 1
    fi
    echo "Success: $1"
    return 0
}

echo "Starting syslog collector cleanup..."

# Stop and disable rsyslog service
echo "Stopping and disabling rsyslog..."
sudo systemctl stop rsyslog
sudo systemctl disable rsyslog
check_status "rsyslog service stop and disable"

# Stop and disable MySQL service
echo "Stopping and disabling MySQL..."
sudo systemctl stop mysql
sudo systemctl disable mysql
check_status "MySQL service stop and disable"

# Remove installed packages
echo "Removing installed packages..."
sudo apt purge -y rsyslog rsyslog-mysql mysql-server mysql-client mysql-common php7.4-cli php7.4-mysql git net-tools
sudo apt autoremove -y
check_status "Package removal"

# Drop MySQL database and users
echo "Dropping syslog_db database and users..."
sudo mysql -u root <<EOF
DROP DATABASE IF EXISTS syslog_db;
DROP USER IF EXISTS 'Admin'@'localhost';
DROP USER IF EXISTS 'Radmin'@'142.91.101.137';
DROP USER IF EXISTS 'Radmin'@'112.134.219.183';
FLUSH PRIVILEGES;
EOF
check_status "MySQL database and user cleanup"

# Remove rsyslog configuration files
echo "Removing rsyslog configuration files..."
sudo rm -f /etc/rsyslog.d/50-mysql.conf
sudo rm -f /etc/rsyslog.d/50-ports.conf
sudo rm -f /var/log/remote_syslog.log
check_status "rsyslog configuration cleanup"

# Reset /etc/rsyslog.conf by removing imudp module
echo "Resetting /etc/rsyslog.conf..."
if [ -f /etc/rsyslog.conf ]; then
    sudo sed -i '/module(load="imudp")/d' /etc/rsyslog.conf
    sudo sed -i '/input(type="imudp" port="514")/d' /etc/rsyslog.conf
    check_status "rsyslog.conf reset"
else
    echo "Warning: /etc/rsyslog.conf not found. Skipping reset."
fi

# Remove firewall rules
echo "Removing firewall rules..."
sudo ufw delete allow 514/udp
sudo ufw delete allow 514/tcp
sudo ufw delete allow 512/tcp
sudo ufw delete allow 1024/tcp
sudo ufw delete allow 22/tcp
sudo ufw --force enable
check_status "Firewall rules cleanup"

# Remove Git repository
echo "Removing Git repository..."
sudo rm -rf /var/www/html/setup-active-syslog/syslog-collector-portManger
check_status "Git repository cleanup"

# Restore MySQL bind-address to default (127.0.0.1)
echo "Restoring MySQL bind-address..."
sudo sed -i 's/bind-address\s*=\s*0.0.0.0/bind-address = 127.0.0.1/' /etc/mysql/mysql.conf.d/mysqld.cnf
check_status "MySQL bind-address restore"

# Clean up any residual MySQL configuration files
echo "Cleaning up MySQL configuration files..."
sudo rm -f /etc/dbconfig-common/rsyslog-mysql.conf
sudo rm -f /etc/rsyslog.d/mysql.conf
check_status "MySQL configuration cleanup"

# Verify cleanup
echo "Verifying cleanup..."
if [ -f /etc/rsyslog.d/50-mysql.conf ] || [ -f /etc/rsyslog.d/50-ports.conf ] || [ -f /var/log/remote_syslog.log ]; then
    echo "Warning: Some rsyslog files remain. Please check /etc/rsyslog.d/ and /var/log/"
else
    echo "rsyslog files successfully removed."
fi

if [ -d /var/www/html/setup-active-syslog/syslog-collector-portManger ]; then
    echo "Warning: Git repository directory still exists."
else
    echo "Git repository successfully removed."
fi

echo "Checking for remaining packages..."
dpkg -l | grep -E 'rsyslog|mysql|php7.4|git|net-tools' || echo "No related packages found."

echo "Cleanup complete! System is ready for a fresh setup_syslog_collector.sh run."