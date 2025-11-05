# Use minimal base
FROM alpine:latest

# Install Squid
RUN apk add --no-cache openssl squid apache2-utils

# Copy your custom squid.conf if available
# (Place your config file in the same directory as this Dockerfile)
COPY --chmod=640 --chown="$SQUID_USER":"$SQUID_USER" ./files/squid.conf /etc/squid/squid.conf

COPY --chmod=777 ./files/entrypoint.sh /usr/local/bin/entrypoint.sh

# Create cache directories and set permissions
RUN mkdir -p /var/cache/squid /var/log/squid && \
  chown -R squid:squid /var/cache/squid /var/log/squid

# Expose Squid default port
EXPOSE 3128/tcp

# Run as non-root user for better security
# USER squid
ENTRYPOINT ["entrypoint.sh"]

# Start Squid in the foreground
#CMD ["squid", "-N", "-d", "1"]

