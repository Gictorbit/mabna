# syntax=docker/dockerfile:1.4
ARG COMPRESS="true"
FROM migrate/migrate:latest AS migrate

# install dependensies
RUN sed -i 's#dl-cdn.alpinelinux.org#alpine.global.ssl.fastly.net#g' /etc/apk/repositories
RUN apk add --update --no-cache upx

ARG COMPRESS
RUN if [ "$COMPRESS" = "true" ] ;then upx --best --lzma /usr/local/bin/migrate;fi

FROM scratch AS final

WORKDIR /sqls
COPY "./migrations" .

WORKDIR /app
COPY --from=migrate /usr/local/bin/migrate .
ENTRYPOINT ["./migrate"]
CMD ["--help"]