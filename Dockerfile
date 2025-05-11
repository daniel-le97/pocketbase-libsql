# Use the official Golang image to create a build artifact.
FROM golang:1.23-bookworm AS builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

ARG ZIG_VERSION=0.13.0

# **Install zig manually** #
# ARG ZIG_ARCH=aarch64
# RUN apt-get update && apt-get install -y unzip xz-utils \
#     && wget https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz \
#     && tar -xf zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz \
#     && mv zig-linux-${ZIG_ARCH}-${ZIG_VERSION} /usr/local/zig \
#     && ln -s /usr/local/zig/zig /usr/local/bin/zig \
#     && rm zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz
# RUN apt-get update && apt-get install -y libc6-dev clang

RUN apt-get update && apt-get install -y unzip xz-utils

RUN curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash \
    && /root/.zvm/self/zvm install ${ZIG_VERSION}

# Copy the source from the current directory to the Working Directory inside the container
COPY . .

# Build the Go app
ENV CGO_ENABLED=1
ENV CC="/root/.zvm/bin/zig cc"
ENV CXX="/root/.zvm/bin/zig c++"
# Set a writable temporary directory for Go
ENV GOTMPDIR=/tmp

RUN go build -ldflags '-s -w -extldflags "-lc -lunwind -static"' -o main main.go

# Start a new stage from scratch
FROM frolvlad/alpine-glibc AS production
# RUN apt-get update && apt-get install -y ca-certificates

WORKDIR /root/

# Add OCI label for the source repository
LABEL org.opencontainers.image.source="https://github.com/daniel-le97/pocketbase-libsql"

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /app/main ./
# COPY --from=builder /app/pb_hooks ./pb_hooks
# COPY --from=builder /app/pb_migrations ./pb_migrations
# COPY --from=builder /app/pb_data ./pb_data/
# COPY --from=builder /app/pb_public ./pb_public/

# Expose port 8090 to the outside world
EXPOSE 8090

# Set a default environment variable for the port
ENV PORT=8090

# Command to run the executable
CMD ["sh", "-c", "./main serve --http=0.0.0.0:${PORT}"]
