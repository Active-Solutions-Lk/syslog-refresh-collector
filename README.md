# syslog-refresh-collector

## Overview

`refresh_collector.sh` is a cleanup script for syslog collector environments.

### What It Does

- **Services:** Stops and disables `rsyslog` and `mysql` to prevent interference during cleanup.
- **Packages:** Purges `rsyslog`, `rsyslog-mysql`, `mysql-server`, `mysql-client`, `mysql-common`, `php7.4-cli`, `php7.4-mysql`, `git`, and `net-tools`. Runs `apt autoremove` to clean up dependencies.
- **MySQL:** Drops the `syslog_db` database and users:
    - `Admin@localhost`
    - `Radmin@142.91.101.137`
    - `Radmin@112.134.219.183`
- **rsyslog:** Removes:
    - `/etc/rsyslog.d/50-mysql.conf`
    - `/etc/rsyslog.d/50-ports.conf`
    - `/var/log/remote_syslog.log`
    - The `imudp` module from `/etc/rsyslog.conf`
- **Firewall:** Deletes rules for ports `514/udp`, `514/tcp`, `512/tcp`, `1024/tcp`, and `22/tcp`.  
    > **Note:** If port `22/tcp` (SSH) is required for system access, re-enable it manually after cleanup.
- **Git Repository:** Removes the `syslog-collector-portManger` directory.
- **MySQL Config:** Restores `bind-address = 127.0.0.1` and removes:
    - `/etc/dbconfig-common/rsyslog-mysql.conf`
    - `/etc/rsyslog.d/mysql.conf` (created by `rsyslog-mysql`)
- **Verification:** Checks for residual files and packages to confirm cleanup.

---

## Usage Instructions

### 1. Save the Script

Save `refresh_collector.sh` in `/var/www/html/setup-active-syslog`.

Make it executable:

```bash
chmod +x /var/www/html/setup-active-syslog/refresh_collector.sh
```

### 2. Run the Script

```bash
sudo bash /var/www/html/setup-active-syslog/refresh_collector.sh
```

### 3. Verify Cleanup

**Check for remaining files:**

```bash
ls /etc/rsyslog.d/
ls /var/log/remote_syslog.log
ls /var/www/html/setup-active-syslog/syslog-collector-portManger
```
*Expected output: No files or directories found.*

**Check for remaining packages:**

```bash
dpkg -l | grep -E 'rsyslog|mysql|php7.4|git|net-tools'
```
*Expected output: No packages listed.*

**Check MySQL databases:**

```bash
sudo mysql -u root -e "SHOW DATABASES;"
```
*Ensure `syslog_db` is not listed.*

**Check firewall rules:**

```bash
sudo ufw status
```
*Confirm ports 514, 512, 1024 are not listed (re-enable 22/tcp if needed for SSH).*

---

### 4. Run `setup_syslog_collector.sh`

After cleanup, run the updated `setup_syslog_collector.sh` to set up the syslog collector fresh.