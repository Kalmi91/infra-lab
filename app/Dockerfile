# Multi-stage build -> tiny distroless image (~10MB, no shell, non-root).
FROM golang:1.23 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION}" -o /demoapp .

FROM gcr.io/distroless/static:nonroot
COPY --from=build /demoapp /demoapp
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/demoapp"]
