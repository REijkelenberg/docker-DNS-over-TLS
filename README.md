
# Docker DNS-over-TLS

This container contains a simple Nginx reverse proxy for providing DNS-over-TLS (DoT). Upstream, Pi-hole could be used to block domains that distribute advertisements or malware.

Valid TLS certificates are required if you whish to use this container. You can obtain such certificates for free from e.g. [LetsEncrypt](https://letsencrypt.org/), or create self-signed certificates using e.g. the openssl command-line tool (not recommended for public use).

## Network overview

```
+---------------+       +---------------+       +---------------+
|               |       |               |       |               |
|   Client      |--TCP--|   Reverse     |--UDP--|   Upstream    |
|   device      | (TLS) |   proxy       |       |   DNS server  |
|               |       |               |       |               |
+---------------+       +---------------+       +---------------+
```

## How to run this container

Running this container is pretty straightforward. However, note the following:

* DoT is typically being offered on port 853. Publish this port (`-p 853:853`) unless you want to offer DoT on another port.
* As the name suggests, TLS is being used to encrypt DNS traffic between the client and container. Using environment variables, let Nginx know where to find your TLS certificate and the corresponding private key:
	* `TLS_CERTIFICATE`: Path to the TLS certificate (make sure the storage volume on which the certificate resides is accessible to the container; read-only access _probably_ suffices).
	* `TLS_CERTIFICATE_KEY`: Path to the TLS certificate's private key (again, make sure that the container has at least read-only access to this file).
* Optionally, tell Nginx which upstream DNS server it must use by setting the environment variables `DNS_UPSTREAM_ADDRESS` _(default: `127.0.0.1`)_ and `DNS_UPSTREAM_PORT` _(default: 53)_ accordingly. Note that the container itself does _not_ use that upstream DNS server, but uses the Docker default address instead. You can configure this on a per container basis using the `--dns` flag.
* Optionally, tell the container not to initialise itself by setting `FIRST_RUN_AUTO_INIT` to `false` (more info below).

Example Docker command for a typical use-case:
`docker run -d --name dns-over-tls -p 853:853 -v /path/to/certificate/directory/on/host:/certificates -e DNS_UPSTREAM_ADDRESS="1.1.1.1" -e TLS_CERTIFICATE="/certificates/fullchain.pem" -e TLS_CERTIFICATE_KEY="/certificates/privkey.pem" reijkelenberg/dns-over-tls`.

## Environment variables

| Variable                  | Default value | Description                                |
| ------------------------- |:------------- | ------------------------------------------ |
| `DNS_UPSTREAM_ADDRESS`    | `127.0.0.1`   | IP address of upstream DNS server.         |
| `DNS_UPSTREAM_PORT`       | `53`          | DNS service port of upstream DNS server.   |
| `FIRST_RUN_AUTO_INIT`     | `true`        | Whether the container should auto-initialise itself on first run (see below). |
| `TLS_CERTIFICATE`         | `""`          | Path to the TLS certificate.               |
| `TLS_CERTIFICATE_KEY`     | `""`          | Path to the TLS certificate's private key. | 

## AUTO_INIT
By default, when the container is starting for the first time, a script will run that configures the Nginx reverse proxy. The script does two things: 1) It points Nginx to the right TLS certificates, and 2) it tells Nginx which upstream DNS server it must use. If you wish to setup Nginx manually, set `FIRST_RUN_AUTO_INIT` to `false`.
