FROM ubuntu:22.04

RUN apt-get update && apt-get install -y procps bc

COPY server-stats-cabero07.sh /usr/local/bin/server-stats.sh

RUN chmod +x /usr/local/bin/server-stats.sh

CMD ["/usr/local/bin/server-stats.sh"]