FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./

RUN apk add --no-cache gcc musl-dev make git

# 安装跨平台编译工具链
RUN apk add --no-cache --virtual .build-deps \
    gcc-aarch64-linux-gnu \
    gcc-x86_64-linux-gnu

# 安装依赖并验证
RUN go mod download && go mod verify

COPY . .

# 使用动态架构参数
ARG TARGETOS TARGETARCH
RUN CGO_ENABLED=1 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/main .

RUN apk add --no-cache ca-certificates tzdata

CMD ["./main"]