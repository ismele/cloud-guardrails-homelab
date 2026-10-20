#!/usr/bin/env bash
# node_exporter + Prometheus (official release binaries) and Grafana (signed vendor repo).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ARCH=linux-amd64

id prometheus &>/dev/null || useradd --system --no-create-home --shell /sbin/nologin prometheus
latest() { curl -s "https://api.github.com/repos/prometheus/$1/releases/latest" | grep -m1 '"tag_name"' | cut -d'"' -f4 | tr -d v; }
NE="$(latest node_exporter)"; PV="$(latest prometheus)"
[[ -n "$NE" && -n "$PV" ]] || { echo "Could not resolve release versions"; exit 1; }
echo "node_exporter $NE / prometheus $PV"

tmp="$(mktemp -d)"; cd "$tmp"
curl -sLO "https://github.com/prometheus/node_exporter/releases/download/v$NE/node_exporter-$NE.$ARCH.tar.gz"
curl -sLO "https://github.com/prometheus/prometheus/releases/download/v$PV/prometheus-$PV.$ARCH.tar.gz"
tar xzf "node_exporter-$NE.$ARCH.tar.gz"; tar xzf "prometheus-$PV.$ARCH.tar.gz"
install -m 0755 "node_exporter-$NE.$ARCH/node_exporter" /usr/local/bin/
install -m 0755 "prometheus-$PV.$ARCH/prometheus" "prometheus-$PV.$ARCH/promtool" /usr/local/bin/
cd /; rm -rf "$tmp"

mkdir -p /etc/prometheus /var/lib/prometheus
cp "$HERE/config/prometheus/prometheus.yml" "$HERE/config/prometheus/alerts.yml" /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
promtool check config /etc/prometheus/prometheus.yml

cp "$HERE/config/systemd/node_exporter.service" "$HERE/config/systemd/prometheus.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now node_exporter prometheus

cp "$HERE/config/grafana/grafana.repo" /etc/yum.repos.d/grafana.repo
rpm --import https://rpm.grafana.com/gpg.key
dnf -y install grafana
cp "$HERE/config/grafana/prometheus-datasource.yml" /etc/grafana/provisioning/datasources/prometheus.yml
systemctl enable --now grafana-server

systemctl status node_exporter prometheus grafana-server --no-pager | grep -E "●|Active:"
echo "Grafana: http://<server-ip>:3000 (change the admin password on first login)."
echo "Tip: import dashboard ID 1860 (Node Exporter Full)."
