# syntax=docker/dockerfile:1.4
ARG GO_VERSION="1.21.5"
ARG GOPROXYURL="https://goproxy.io,direct"
ARG COMPRESS="true"
ARG GITHUB_TOKEN

FROM golang:${GO_VERSION}-alpine AS builder
# install packages
RUN sed -i 's#dl-cdn.alpinelinux.org#alpine.global.ssl.fastly.net#g' /etc/apk/repositories
RUN apk --no-cache add --update ca-certificates tzdata upx git

# config git
ARG GITHUB_TOKEN
RUN git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com".insteadOf "https://github.com"

# copy source code
WORKDIR /build
COPY . .

# Get all of our dependencies
ARG GOPROXYURL
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod GOPROXY="${GOPROXYURL}" go mod download -x
# compile project
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags "-s -w" -a -installsuffix cgo -o ./bin/financeserv ./cmd/main

ARG COMPRESS
RUN mkdir -p /final && \
    if [ "$COMPRESS" = "true" ] ;then upx --best --lzma -o /final/usersrv ./bin/financeserv ;else cp ./bin/financeserv /final; fi

FROM scratch AS final

WORKDIR /production
COPY --from=builder /final .
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

ENTRYPOINT ["./financeserv"]