# Use the official Golang image to create a build artifact.
# This is the build stage.
FROM golang:1.23-bullseye AS builder


# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

ARG ZIG_VERSION=0.13.0
ARG ZIG_ARCH=x86_64

RUN apt-get update && apt-get install -y wget unzip xz-utils \
    && wget https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz \
    && tar -xf zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz \
    && mv zig-linux-${ZIG_ARCH}-${ZIG_VERSION} /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    && rm zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz
# RUN apt-get update && apt-get install -y libc6-dev clang

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

# Build the Go app
ENV CGO_ENABLED=1
ENV CC="zig cc -target ${ZIG_ARCH}-linux-gnu -isystem /usr/include"
ENV CXX="zig c++ -target ${ZIG_ARCH}-linux-gnu -isystem /usr/include"
ENV GOARCH=amd64
ENV GOOS=linux 
# ENV OK=-ldflags '-extldflags "-ldl -lc -static"' 
RUN go build -ldflags '-s -w -extldflags "-lc -lunwind -static"' -o main main.go

# Start a new stage from scratch
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates

WORKDIR /root/

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/main ./
COPY --from=builder /app/.env ./
# COPY --from=builder /app/pb_hooks ./pb_hooks
# COPY --from=builder /app/pb_migrations ./pb_migrations
# COPY --from=builder /app/pb_data ./pb_data/
# COPY --from=builder /app/combined.json ./

# Expose port 8090 to the outside world
EXPOSE 8090

# Set a default environment variable for the port
ENV PORT=8090

# Command to run the executable
CMD sh -c "./main serve --http=0.0.0.0:${PORT}"
