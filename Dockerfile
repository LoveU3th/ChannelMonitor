FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./

RUN apk add --no-cache gcc musl-dev make git

# 更新 go.mod 和 go.sum
RUN go mod download golang.org/x/time && \
    go mod tidy

COPY . .

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/main .

RUN apk add --no-cache ca-certificates tzdata

CMD ["./main"]