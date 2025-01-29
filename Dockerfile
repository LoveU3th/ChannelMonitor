FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./

# 安装基础编译工具
RUN apk add --no-cache gcc musl-dev make git

# 安装依赖并验证
RUN go mod download && go mod verify

COPY . .

# 编译
RUN CGO_ENABLED=1 go build -ldflags="-extldflags=-static" -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/main .

RUN apk add --no-cache ca-certificates tzdata

CMD ["./main"]