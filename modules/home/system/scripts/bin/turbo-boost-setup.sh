#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TurboBoostManager - Intel CPU Turbo Boost Kontrol Servisi
#
# Bu script Intel CPU'lar için Turbo Boost özelliğini kontrol eden
# bir systemd servisi kurar. Temel özellikleri:
#
# - Intel pstate sürücüsü ile entegrasyon
# - Systemd servis ve hedef yapılandırması
# - Sistem başlangıcında otomatik Turbo Boost kontrolü
# - Journal entegrasyonlu loglama
# - Servis durumu izleme
#
# Servis Özellikleri:
# - /sys/devices/system/cpu/intel_pstate/no_turbo üzerinden kontrol
# - ExecStart ile Turbo Boost devre dışı bırakma
# - ExecStop ile Turbo Boost etkinleştirme
# - RemainAfterExit desteği
#
# Gereksinimler:
# - Intel CPU ve pstate sürücüsü
# - Root erişimi
# - Systemd
#
# License: MIT
#
#######################################
SERVICE_NAME="cpu-turbo.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
TARGET_PATH="/etc/systemd/system/system-cpu-performance.target"

# Target file content
cat <<'EOF' >/tmp/system-cpu-performance.target
[Unit]
Description=CPU Performance Management Target
Requires=multi-user.target
After=multi-user.target

[Install]
WantedBy=multi-user.target
EOF

# Service content
cat <<'EOF' >/tmp/cpu-turbo.service
[Unit]
Description=Intel CPU Turbo Boost Control Service
Documentation=https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html
After=multi-user.target
DefaultDependencies=yes

[Service]
Type=oneshot
ExecStart=/bin/bash -c '\
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then \
    echo "1" > /sys/devices/system/cpu/intel_pstate/no_turbo && \
    echo "Turbo Boost disabled successfully" || \
    echo "Failed to disable Turbo Boost" >&2; \
else \
    echo "Intel pstate driver not found" >&2; \
    exit 1; \
fi'

ExecStop=/bin/bash -c '\
if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then \
    echo "0" > /sys/devices/system/cpu/intel_pstate/no_turbo && \
    echo "Turbo Boost enabled successfully" || \
    echo "Failed to enable Turbo Boost" >&2; \
fi'

RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=system-cpu-performance.target
EOF

# Root check
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Copy files
mv /tmp/system-cpu-performance.target "$TARGET_PATH"
mv /tmp/cpu-turbo.service "$SERVICE_PATH"
chmod 644 "$SERVICE_PATH" "$TARGET_PATH"

# Reload and start
systemctl daemon-reload
systemctl enable system-cpu-performance.target
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Check service status
STATUS=$(systemctl is-active "$SERVICE_NAME")
if [ "$STATUS" = "active" ]; then
  echo -e "\n✅ Installation Completed Successfully"
  echo "- Service installed at: $SERVICE_PATH"
  echo "- Target installed at: $TARGET_PATH"
  echo "- Service status: Active"
  echo "- Turbo Boost will be disabled on system startup"
  echo "- To check logs: journalctl -u $SERVICE_NAME"
  echo "- To enable Turbo Boost: systemctl stop $SERVICE_NAME"
  echo "- To disable Turbo Boost: systemctl start $SERVICE_NAME"
else
  echo -e "\n❌ Installation Failed"
  echo "Service status: $STATUS"
  echo "Check logs with: journalctl -u $SERVICE_NAME"
fi
