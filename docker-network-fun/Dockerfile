FROM rabbitmq:3.8.6-management

RUN \
  apt update && \
  apt -y install iproute2 netcat iputils-ping iptables net-tools tcpdump vim iperf

COPY rabbitmq.conf /etc/rabbitmq/rabbitmq.conf

ARG MEMORY_WATERMARK
ARG DISK_WATERMARK

RUN \
  sed -i "s|<MEMORY_WATERMARK>|${MEMORY_WATERMARK}MB|g" /etc/rabbitmq/rabbitmq.conf && \
  sed -i "s|<DISK_WATERMARK>|${DISK_WATERMARK}MB|g" /etc/rabbitmq/rabbitmq.conf
