# Lessons learned

1. **Read the guardrails first.** Instance types, volume types (gp2 vs. the gp3 default), vCPU totals, and credit modes can all be enforced. Design inside them instead of finding out after a launch fails.
2. **When a control is blocked, change layers, and write down the gap.** OS-level encryption kept the data encrypted at rest, but it moved key management onto me.
3. **Break things on purpose.** Running the CPU drill taught me more about alert timing than any documentation did.
4. **Static for what others depend on, dynamic for what's disposable.** Use a fixed private IP and an Elastic IP for the server, and DHCP for admin or test machines. Reference security groups, not IPs, in rules, because rebuilt environments get new addresses.
5. **Right-size with measurements.** Estimate memory first, then confirm with the dashboard at idle and under load before choosing a bigger instance.

## References

- AWS: [Amazon EBS encryption](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-encryption.html), [AL2023 release cadence](https://docs.aws.amazon.com/linux/al2023/ug/release-cadence.html), [Elastic IP addresses](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)
- NIST SP 800-38E, [XTS-AES mode for storage devices](https://doi.org/10.6028/NIST.SP.800-38E)
- RFC 9106, [Argon2](https://doi.org/10.17487/RFC9106)
- Prometheus, [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- Grafana, [Install on RHEL/Fedora](https://grafana.com/docs/grafana/latest/setup-grafana/installation/redhat-rhel-fedora/)
