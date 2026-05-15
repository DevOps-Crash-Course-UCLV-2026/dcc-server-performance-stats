FROM debian:stable-slim

LABEL maintainer="drgalpert"

# Install a minimal set of utilities the script expects (bash, ps, df, awk, free, uptime)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    bash \
    procps \
    coreutils \
    gawk \
    util-linux \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy the script into the image, strip CRLF line endings, and make it executable
COPY server-stats-drgalpert.sh /tmp/server-stats-drgalpert.sh
RUN sed 's/\r$//' /tmp/server-stats-drgalpert.sh > /usr/local/bin/server-stats-drgalpert.sh && chmod +x /usr/local/bin/server-stats-drgalpert.sh && rm /tmp/server-stats-drgalpert.sh

# The container should print the report immediately on startup
ENTRYPOINT ["/usr/local/bin/server-stats-drgalpert.sh"]
