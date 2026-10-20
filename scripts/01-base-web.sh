#!/usr/bin/env bash
# Base packages and a placeholder web page. Amazon Linux 2023.
set -euo pipefail
dnf -y install httpd mod_ssl rsyslog chrony tar logrotate cryptsetup
systemctl enable --now httpd chronyd rsyslog
echo '<h1>Homelab web server</h1><p>web01</p>' > /var/www/html/index.html
curl -s http://localhost | head -1
