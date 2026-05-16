FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
    procps \
    bc \
    coreutils && \
    apt-get clean

WORKDIR /app

COPY server-stats-jeizquierdo.sh .

RUN chmod +x server-stats-jeizquierdo.sh

CMD ["./server-stats-jeizquierdo.sh"]