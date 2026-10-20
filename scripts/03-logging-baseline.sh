#!/usr/bin/env bash
# Persistent journal, split security/warning logs, 90-day rotation.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p /etc/systemd/journald.conf.d /var/log/lab
cp "$HERE/config/logging/journald-retention.conf" /etc/systemd/journald.conf.d/retention.conf
cp "$HERE/config/logging/50-security.conf" /etc/rsyslog.d/50-security.conf
cp "$HERE/config/logging/logrotate-lab" /etc/logrotate.d/lab
systemctl restart systemd-journald rsyslog
logger -p authpriv.notice "homelab: security log test"
logger -p user.warning "homelab: warning log test"
sleep 1
tail -n 2 /var/log/lab/security.log /var/log/lab/warnings.log
