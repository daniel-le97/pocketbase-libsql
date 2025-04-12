# pocketbase-libsql

this is a go project that uses pocketbase as a framework, and uses libsql as a replacement for sqlite

## ENV variables
 1. TURSO_URL
    1. if the url is empty, it will fallback to using libsqls local driver ( sqlite )
    2. if the url starts with "libsql" using the libsql protocol it will assume the URL is from the turso platform in which case TURSO_AUTH_TOKEN must be set
    3. you can use http/https urls for libsql server
 2. TURSO_AUTH_TOKEN
    1. only required if using turso, is not required to be set when using libsql server or the local file driver

## Prerequisites

### Local Development

To build and run the project locally, you need to have the following installed:

- [Go](https://golang.org/doc/install) (version 1.23.4 or later)
- [Zig](https://ziglang.org/download/) (version 0.13.0 or later) or another C compiler


## Installation

### Local Installation

1. Clone the repository:

    ```sh
    git clone https://github.com/daniel-le97/pocketbase-libsql.git
    cd pocketbase-libsql
    ```

2. check if you have all dependencies:

    ```sh
    make check-deps
    ```

3. set enviroment variables accordingly
    ```sh
    cp .env.example .env
    ```

4. build:

    this will build ./dist/build/pb-linux-amd64
    ```sh
    make linux-amd
    ```
    this will build ./dist/build/pb-linux-arm64
    ```sh
    make linux-arm
    ```
### Docker Installation


If you prefer to use Docker, ensure you have Docker installed on your machine. You can download and install Docker from [here](https://www.docker.com/get-started).

1. Clone the repository:

    ```sh
    git clone https://github.com/daniel-le97/pocketbase-libsql.git
    cd pocketbase-libsql
    ```

2. Build the Docker image:

    ```sh
    docker build -t pocketbase-libsql .
    ```
3. run the container:
    ```sh
    docker run -d -p 8090:8090 --name pocketbase-libsql-container -e TURSO_URL=<your_turso_url> pocketbase-libsql
    ```
### Docker compose
1. this runs a self hosted libsql server instance and does not use turso
    ```sh
    docker compose up -d
    ```

## Usage

### Local Usage

To run the project locally, use the following command:

```sh
make run
```

please note this will run "./dist/build/pb-$(GOOS)-$(GOARCH) serve". 

## Makefile

```
Available targets:
 run                  Run the application based on the current OS
 check-deps           Check if required dependencies (Zig and Go) are installed
 install-zig          Install Zig using Go's package manager
 check_and_create_dir Check if the output directory exists, and create it if necessary
 build                Build the application for the specified target or will default to the current OS
 zig-build            Build the application using Zig (use this for cross-compilation)
 linux-arm            Build the application for Linux ARM64
 linux-amd            Build the application for Linux AMD64
 darwin-amd           Build the application for macOS AMD64
 darwin-arm           Build the application for macOS ARM64
 docker-build         Build the Docker image
 docker-compose-up    Start services using Docker Compose
 docker-compose-down  Stop services using Docker Compose
 docker-compose-logs  View logs from Docker Compose services
 docker-login-ghcr    Log in to GitHub Container Registry
 docker-push-ghcr     Push the Docker image to GitHub Container Registry
```

## Notes
currently cross-compiling for darwin and linux only seems to work on a mac device

this does not work for windows yet, as libsql doesnt target it yet check [go-libsql](https://github.com/tursodatabase/go-libsql) for details
