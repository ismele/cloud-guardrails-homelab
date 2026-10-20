#!/usr/bin/env bash
# Drive every CPU to 100% for a fixed time so you can watch alerts fire.
# Usage: bash 07-cpu-alert-drill.sh [seconds]   (default 480 = 8 minutes)
set -euo pipefail
SECS="${1:-480}"
CORES="$(nproc)"
echo "Loading $CORES core(s) for $SECS seconds. Stop early with: pkill -f 'yes'"
for _ in $(seq "$CORES"); do timeout "$SECS" yes > /dev/null & done
echo "Watch: Prometheus /alerts (HighCpu: pending -> firing) and CloudWatch web01-cpu-high."
wait
echo "Drill finished."
