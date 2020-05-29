FROM alpine:3.11
MAINTAINER Decaux Nicolas <decauxnico@gmail.com>

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base iputils git
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

# Update and install all of the required packages.
# At the end, remove the apk cache

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /usr/src/app

WORKDIR /usr/src/app
COPY . /usr/src/app

RUN bundle install

ENV RUBYLIB=/usr/src/app/lib

HEALTHCHECK --interval=10s --timeout=10s --retries=3 --start-period=120s \
    CMD ping -w 8 -4 -c 1 8.8.8.8 || exit 1

EXPOSE 9000

CMD ["./bin/systemd_mon", "/systemd_mon/systemd_mon.yml"]
