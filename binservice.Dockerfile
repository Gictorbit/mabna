# syntax=docker/dockerfile:1.4
FROM scratch AS final

WORKDIR /production

COPY ./bin/service .

ENTRYPOINT ["./service"]