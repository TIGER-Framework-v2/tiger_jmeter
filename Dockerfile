FROM alpine:3.9

MAINTAINER RayJan<rayetskaya@gmail.com>

ARG JM_VER="apache-jmeter-5.1"
ENV JM_HOME_DIR  /opt/${JM_VER}
ENV JM_URL https://archive.apache.org/dist/jmeter/binaries/${JM_VER}.tgz

RUN apk update \
    && apk add openjdk8-jre curl bash\
    && wget ${JM_URL} \
    && tar -xzf ${JM_VER}.tgz -C /opt/ \
    && rm -f ${JM_VER}.tgz

ENV PATH $PATH:${JM_HOME_DIR}/bin

WORKDIR ${JM_HOME_DIR}/bin
