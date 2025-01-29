FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./

RUN apk add --no-cache gcc musl-dev make git

# 添加缺失的依赖并更新 go.mod
RUN go get golang.org/x/time/rate && go mod tidy

RUN go mod download

COPY . .

RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/main .

RUN apk add --no-cache ca-certificates tzdata

CMD ["./main"]