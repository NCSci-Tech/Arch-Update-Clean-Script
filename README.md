## System Maintenance Script (Arch Linux)

### Overview

This script automates regular system maintenance tasks for Arch-based distributions.
It updates system packages, upgrades AUR packages, removes orphaned dependencies, cleans package caches, and updates system databases.

### Script

Save the following as `system_maintenance.sh`:

```bash
#!/bin/bash

# Update official repositories
sudo pacman -Syu

# Update AUR packages (requires yay)
yay -Sua

# Remove orphaned packages
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    sudo pacman -Rns $orphans --noconfirm
else
    echo "No orphaned packages found."
fi

# Clean old package cache
sudo pacman -Sc --noconfirm

# Optionally, clean *all* cache (uncomment if desired)
# sudo pacman -Scc

# Update locate and man databases
sudo updatedb
sudo mandb
```

Make it executable:

```bash
chmod +x system_maintenance.sh
```

Run it manually with:

```bash
./system_maintenance.sh
```
### Important note:
Do NOT run with sudo, if passwweord is required it will ask!

---

## Run on Startup

There are two common methods to run this script automatically at startup (or on a schedule):

### **Option 1: systemd Service**

1. Create a systemd service file:

   ```bash
   sudo nano /etc/systemd/system/system-maintenance.service
   ```
2. Paste this content:

   ```ini
   [Unit]
   Description=System Maintenance Script
   After=network-online.target

   [Service]
   Type=oneshot
   ExecStart=/path/to/system_maintenance.sh
   StandardOutput=journal
   StandardError=journal

   [Install]
   WantedBy=default.target
   ```
3. Enable it to run at boot:

   ```bash
   sudo systemctl enable system-maintenance.service
   ```
4. Test it manually:

   ```bash
   sudo systemctl start system-maintenance.service
   ```

---

### **Option 2: Cron Job (@reboot)**

If you prefer `cron`:

1. Open your user’s crontab:

   ```bash
   crontab -e
   ```
2. Add this line:

   ```bash
   @reboot /path/to/system_maintenance.sh
   ```
3. Save and exit.

> **Tip:** You can also schedule it weekly:
>
> ```bash
> 0 8 * * 1 /path/to/system_maintenance.sh
> ```
>
> (Runs every Monday at 8 AM)

---

### Requirements

* Arch-based Linux distribution
* `yay` installed (for AUR updates)
* Root privileges for system operations

---

### Optional Improvements

* Log output to a file:

  ```bash
  ./system_maintenance.sh | tee -a ~/maintenance.log
  ```
* Schedule with `systemd` timer instead of `cron` for better integration.
