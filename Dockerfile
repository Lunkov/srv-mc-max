# Two-stage build:
#    first  FROM prepares a binary file in full environment ~780MB
#    second FROM takes only binary file ~20MB
FROM golang:1.15 AS builder

# File Author / Maintainer
MAINTAINER ANO "DIGITAL COUNTRY"

RUN apt-get update && apt-get install -y net-tools dnsutils  ca-certificates libproj-dev protobuf-compiler && apt-get clean -y
WORKDIR /root

ENV GO111MODULE=auto
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64
ENV GOROOT=/usr/local/go
ENV GOBIN=/root/go
ENV GOPATH $HOME/go
ENV PATH $PATH:$GOROOT/bin:$GOPATH/bin:$GOROOT:$GOPATH:$GOBIN
ENV CGO_CFLAGS="-g -O2"
ENV CGO_CPPFLAGS=""
ENV CGO_CXXFLAGS="-g -O2"
ENV CGO_FFLAGS="-g -O2"
ENV CGO_LDFLAGS="-g -O2"
#ENV GCCGO="gccgo"
#ENV CC="clang"
#ENV CXX="clang++"
ENV GOGCCFLAGS="-fPIC -m64 -pthread -fno-caret-diagnostics -Qunused-arguments -fmessage-length=0 -gno-record-gcc-switches -fno-common"

RUN cat /etc/*-release
RUN pwd
RUN ls -l /home/
RUN ls -l /root/

RUN mkdir /app && mkdir /app/templates && mkdir /app/etc
ADD *.go /app/
WORKDIR /app/
RUN cd /app

RUN go get -d

# RUN go get -v -d ./...
RUN ls -l
RUN set
RUN go version
RUN go build -a -v -ldflags '-w -extldflags "-static"' -o ./web-service ./...

RUN ls -l /go/src/

#########
# second stage to obtain a very small image
FROM alpine:latest
# File Author / Maintainer
MAINTAINER ANO "DIGITAL COUNTRY"

ENV CGO_ENABLED=0
ENV MY_USER   appuser
ENV MY_GROUP  appgroup

RUN mkdir /app && mkdir /app/static && mkdir /app/etc && mkdir /app/templates  && mkdir /app/storage

VOLUME /app/etc
VOLUME /app/templates
VOLUME /app/storage
VOLUME /app/static

WORKDIR /app

COPY --from=builder /app/web-service /app/web-service
RUN chmod +x /app/web-service && ls -l /app/

# libproj-dev 
RUN apk update && \
    apk add -u ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ADD ./docker/nsswitch.conf /etc/nsswitch.conf

RUN addgroup --gid 1000 $MY_GROUP \
    && adduser -D -G $MY_GROUP -u 1000 $MY_USER \
    && chown -R $MY_USER:$MY_GROUP /var/log \
    && chown -R $MY_USER:$MY_GROUP /app/ \
    && ls -l /app/ && ls -l /
USER $MY_USER

# Run the command on container startup
EXPOSE 3000

CMD ["/app/web-service"]

