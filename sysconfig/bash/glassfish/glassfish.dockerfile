FROM maven:{version}

RUN \
  if [ "$(which microdnf)" != "" ]; then \
    microdnf install unzip; \
  else \
    apt update && apt install -y unzip; \
  fi;

ADD . /opt/
RUN chmod +x /opt/entrypoint.sh

VOLUME /opt/glassfish

ARG major_version
WORKDIR /opt/glassfish/glassfish${major_version}/bin

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD [""]
