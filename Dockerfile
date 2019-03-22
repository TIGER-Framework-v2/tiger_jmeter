FROM alpine:3.9

MAINTAINER RayJan<rayetskaya@gmail.com>

ARG JM_VER="5.1"
ARG JM_NAME="apache-jmeter-${JM_VER}"

ENV JM_HOME_DIR  /opt/$JM_NAME}
ENV JM_URL https://archive.apache.org/dist/jmeter/binaries/${JM_NAME}.tgz

RUN apk update \
    && apk add openjdk8-jre curl bash\
    && wget ${JM_URL} \
    && tar -xzf ${JM_NAME}.tgz -C /opt/ \
    && rm -f ${JM_NAME}.tgz

ENV PATH $PATH:${JM_HOME_DIR}/bin

WORKDIR ${JM_HOME_DIR}/bin
