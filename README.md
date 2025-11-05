# OpenVPN Client for Docker

## What is this and what does it do?
This project provides a containerized OpenVPN client with an integrated Squid HTTP proxy. It includes a kill switch built with `iptables` to block internet connectivity if the VPN tunnel goes down.
The project is designed to work with any VPN provider by supplying the necessary OpenVPN configuration file(s).

## Why?
Using a containerized VPN client allows you to:
- Easily manage which applications use the VPN by leveraging container networking.
- Avoid installing an OpenVPN client on the host machine.
- Log traffic passing through the Squid proxy for monitoring or debugging purposes.
- Provide application-specific access to the VPN network instead of routing the entire network through the VPN.

## How do I use it?
### Getting the image
You can either pull the image or build it yourself.

To pull the image:
```bash
docker pull openvpn-client-image:latest
```

To build it yourself:
```bash
docker-compose build
```

### Creating and running the container
The project requires the following environment variables to be set at runtime:
- `OVPN_USER`: OpenVPN username
- `OVPN_PASS`: OpenVPN password
- `SQUID_AUTH_USER`: Squid proxy username
- `SQUID_AUTH_PASS`: Squid proxy password

Example:
```bash
OVPN_USER=your_vpn_user OVPN_PASS=your_vpn_pass SQUID_AUTH_USER=proxy_user SQUID_AUTH_PASS=proxy_pass docker compose up
```

### Docker Compose Configuration
Below is an example `docker-compose.yml` configuration:
```yaml
services:
  openvpn-client:
    image: openvpn-client-image:latest
    container_name: openvpn-client-container
    build:
      dockerfile: Dockerfile
      context: ovpn-build
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - ./config:/config:ro
    ports:
      - "3128:3128"
    dns:
      - 8.8.8.8
      - 1.1.1.1
    restart: unless-stopped
    networks:
      - shared-network
    env_file:
      - ./ovpn-build/openvpn.env
    environment:
      - OVPN_USER
      - OVPN_PASS

  squid:
    image: squid-image:latest
    container_name: squid-container
    network_mode: service:openvpn-client
    build:
      dockerfile: Dockerfile
      context: squid-build
    restart: unless-stopped
    volumes:
      - squid_logs:/var/log/squid
    env_file:
      - ./squid-build/squid.env
    environment:
      - SQUID_AUTH_USER
      - SQUID_AUTH_PASS

networks:
  shared-network:
    name: shared-network

volumes:
  squid_logs:
```

### Verifying functionality
To verify that the VPN and proxy are working correctly, you can:
1. Check the public IP of the container:
   ```bash
   docker exec openvpn-client-container wget -qO - ifconfig.me
   ```
2. Ensure Squid proxy authentication works by connecting to the proxy with the provided credentials.

### Troubleshooting
#### VPN Authentication
If your OpenVPN configuration file does not include authentication, ensure you provide the `OVPN_USER` and `OVPN_PASS` environment variables at runtime. These credentials will be dynamically used to create a temporary file within the container.

#### Squid Proxy Authentication
Squid proxy credentials are dynamically generated at runtime using the `SQUID_AUTH_USER` and `SQUID_AUTH_PASS` environment variables. Ensure these are set correctly when starting the container.

### Example .env Files

Below are example `.env` files for the OpenVPN and Squid configurations. Ensure these files are not pushed to version control as they may contain sensitive information.

#### `ovpn-build/openvpn.env`
```plaintext
CONFIG_FILE=/config/example.ovpn
KILL_SWITCH=1
ALLOWED_SUBNETS=192.168.0.0/24,192.168.1.0/24
```

#### `squid-build/squid.env`
```plaintext
SQUID_DIR_CACHE=/var/spool/squid
SQUID_DIR_LOG=/var/log/squid
SQUID_DIR_LIB=/var/lib/squid
SQUID_USER=squid
SQUID_DH_SIZE=1024
SQUID_DOCKER_LOGS=yes
SQUID_DOCKER_LOGS_CACHE=yes
SQUID_CERT_CN="/CN=Forward Proxy"
SQUID_DIR_CONF="/etc/squid"
PASSWD_FILE="/etc/squid/passwd"
```

---

For more details, refer to the `docker-compose.yml` file and the scripts in the `ovpn-build` and `squid-build` directories.


# next release targets:
- tls connection client between proxy server.
- sock5 better for systemwide tunneling.
- better auth for proxy
- visualize proxy server logs
