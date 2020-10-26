FROM maven:3.6.3-jdk-14

RUN \
  microdnf install \
    git

RUN \
  mkdir -p /build && \
  cd /build && \
  git clone https://github.com/eclipse-ee4j/glassfish.git && \
  cd glassfish && \
  git fetch --all && \
  git checkout tags/5.1.0

RUN \
  cd /build/glassfish && \
  mvn dependency:go-offline

RUN \
  cd /build/glassfish && \
  mvn install
