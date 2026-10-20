#!/usr/bin/env bash
# Self-signed certificate for a closed test environment. Use ACM or a public CA for real users.
# Usage: sudo bash 05-self-signed-tls.sh web.example.local
set -euo pipefail
CN="${1:-web.example.local}"
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout /etc/pki/tls/private/web.key -out /etc/pki/tls/certs/web.crt \
  -subj "/O=Homelab/CN=$CN"
chmod 0600 /etc/pki/tls/private/web.key
sed -i 's#^SSLCertificateFile .*#SSLCertificateFile /etc/pki/tls/certs/web.crt#; s#^SSLCertificateKeyFile .*#SSLCertificateKeyFile /etc/pki/tls/private/web.key#' /etc/httpd/conf.d/ssl.conf
apachectl configtest
systemctl restart httpd
curl -vk https://localhost 2>&1 | grep -E "SSL connection|subject:|HTTP/"
