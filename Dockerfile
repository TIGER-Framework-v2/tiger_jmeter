FROM alpine:3.9

MAINTAINER TIGER team <tiger.framework.team@gmail.com>

COPY ./scripts /opt/tiger/scripts
RUN ["/bin/sh", "/opt/tiger/scripts/install.sh"]

WORKDIR /opt/tiger/scripts
ENTRYPOINT ["/usr/bin/ruby","run_test.rb"]



