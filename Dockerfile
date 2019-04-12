FROM alpine:3.9

MAINTAINER TIGER team <tiger.framework.team@gmail.com>

ARG JM_VER="5.1.1"
ARG JM_NAME="apache-jmeter-${JM_VER}"

ENV JM_HOME_DIR=/opt/$JM_NAME} \
    JM_URL="https://archive.apache.org/dist/jmeter/binaries/${JM_NAME}.tgz" \
    PATH=$PATH:${JM_HOME_DIR}/bin


RUN apk update \
    && apk upgrade \
    && apk add ca-certificates \
    && update-ca-certificates \
    && apk add --no-cache nss openjdk8-jre tzdata git ruby \
    && rm -rf /var/cache/apk/* \
    && wget -O ${JM_NAME}.tgz ${JM_URL} \
    && tar -xzf ${JM_NAME}.tgz -C /opt/ \
    && rm -f ${JM_NAME}.tgz \
    && mkdir -p /opt/tiger/scripts /opt/tiger/tests 

COPY ./scripts /opt/tiger/scripts
ENTRYPOINT ["/usr/bin/ruby","/opt/tiger/scripts/run_test.rb"]



