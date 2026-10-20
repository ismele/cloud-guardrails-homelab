# Two-layer monitoring

![two-layer monitoring](images/03_two_layer_monitoring.png)

The CloudWatch agent needs an IAM instance role for memory and disk metrics. With role creation blocked, I split monitoring into two layers that need no role and don't depend on each other.

## Layer 1: inside the VM

- **node_exporter** bound to `127.0.0.1:9100`, so nothing outside the host can read raw metrics
- **Prometheus** scrapes every 15 s, keeps 15 days, evaluates [`alerts.yml`](../config/prometheus/alerts.yml)
- **Grafana** reads Prometheus through a provisioned data source (repeatable, no clicking)

| Alert | Condition | Why |
|---|---|---|
| HighMemory | > 80% for 10 min | Web worker growth shows here first |
| RootDiskFilling | > 85% for 10 min | A full disk stops logging and the web server |
| HighCpu | > 85% for 5 min | Sustained load, not a spike |
| ExporterDown | target down 1 min | Silent monitoring is worse than none |

The `for:` clause is what keeps short spikes from paging anyone: a rule is *pending* until the condition has held for the full window, then *firing*.

## Layer 2: outside the VM

EC2 publishes CPU, network, and status check metrics with no agent. Two alarms go to an SNS email topic ([`scripts/06-cloudwatch-alarms.sh`](../scripts/06-cloudwatch-alarms.sh)):

| Alarm | Condition |
|---|---|
| web01-cpu-high | CPUUtilization > 70%, 2 of 3 five-minute periods |
| web01-status-check | StatusCheckFailed ≥ 1, 2 of 2 one-minute periods |

If the OS hangs, Prometheus goes down with it. The status check alarm still fires.

## Logging

[`scripts/03-logging-baseline.sh`](../scripts/03-logging-baseline.sh): persistent journal (500 MB, 90 days), security and warning events split into `/var/log/lab/`, daily rotation with 90 copies. Weakness: logs still live on the server they describe. In production, ship them off-host with the CloudWatch agent.

## Network exposure

Keep ports intentional and check them:

```bash
sudo ss -tulpn   # expect 22, 80, 443, 3000, 9090; 9100 on 127.0.0.1 only
```
Restrict 3000/9090 to an admin source, and allow SSH only from the EC2 Instance Connect prefix list for your Region.
