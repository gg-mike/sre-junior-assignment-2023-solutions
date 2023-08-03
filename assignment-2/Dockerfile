FROM golang:alpine AS builder
RUN apk --no-cache add curl
ENV BIND_ADDRESS=8080
WORKDIR /src
COPY go.mod main.go ./
RUN go mod download
RUN go build -o /bin/app
FROM scratch
COPY --from=builder /bin/app /bin/app
COPY --from=builder /usr/bin/curl /usr/bin/curl
ENTRYPOINT ["/bin/app"]
