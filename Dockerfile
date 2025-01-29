FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./

# 添加社区仓库并更新索引
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update

# 安装基础编译工具
RUN apk add --no-cache gcc musl-dev make git

# 安装跨平台编译工具链（更新后的配置）
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache --virtual .build-deps \
    musl-dev-cross \
    gcc-aarch64-linux-musl \
    gcc-x86_64-linux-musl

# 安装依赖并验证
RUN go mod download && go mod verify

COPY . .

# 使用动态架构参数
ARG TARGETOS TARGETARCH
RUN case ${TARGETARCH} in \
    "amd64") CC=x86_64-linux-musl-gcc ;; \
    "arm64") CC=aarch64-linux-musl-gcc ;; \
    esac && \
    CGO_ENABLED=1 GOOS=${TARGETOS} GOARCH=${TARGETARCH} CC=${CC} \
    go build -ldflags="-extldflags=-static" -o main .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /build/main .

RUN apk add --no-cache ca-certificates tzdata

CMD ["./main"]