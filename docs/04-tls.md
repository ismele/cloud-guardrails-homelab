# TLS on the web server

[`scripts/05-self-signed-tls.sh`](../scripts/05-self-signed-tls.sh) creates a 2048-bit RSA self-signed certificate and points Apache's `ssl.conf` at it.

Verify:

```bash
curl -vk https://localhost 2>&1 | grep -E "SSL connection|subject:|HTTP/"
# expect TLSv1.3, a TLS_AES_256_GCM_SHA384-class suite, HTTP 200
```

Self-signed is fine for a closed test. For real users, issue a public certificate through AWS Certificate Manager and terminate TLS on a load balancer so renewals are automatic.
