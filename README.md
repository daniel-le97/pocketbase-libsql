# pocketbase-libsql

this is a go project that uses pocketbase as a framework, and uses libsql as a replacement for sqlite.

libsql allows us to have an replicated embeded database, meaning we can deploy multiple instances pointing to the same libsql server, and they will all be in sync with each other.

## Env variables

### Production (.env.example)
    * TURSO_URL
        - if the url is empty, it will fallback to using libsql's local file driver
        - if the url starts with "libsql" using the libsql protocol it will assume the URL is from the turso platform in which case TURSO_AUTH_TOKEN must be set
        - you can use http/https urls for libsql server
    * TURSO_AUTH_TOKEN
        - only required if using turso, is not required to be set when using libsql server or the local file driver

### Development (.env.dev)
    * GITHUB_TOKEN
    * GiTHUB_USERNAME
        - used for creating releases and uploading binaries to github
        - pushing images to ghcr.io

## Local Development

### dependencies
To build and run the project locally, you need to have the following installed:

- [Go](https://golang.org/doc/install) (version 1.23.4 or later)
- [Zig](https://ziglang.org/download/) (version 0.13.0 or later) or another C compiler



### Installation
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
    cp .env.dev .env
    ```

### Building
- Building using default cc compiler (which cc)
    ```sh
    make build
    ```
- Build using zig for linux-amd64
    ```sh
    make linux-amd
    ```
- Build using zig for linux-arm64
    ```sh
    make linux-arm
    ```
- Build using zig for darwin-arm64
    ```sh
    make darwin-arm
    ```
- Build using zig for darwin-amd64
    - you will need to run this once
        ```sh
        make patch-go-libsql
        ```
    ```sh
    make darwin-amd
    ```
- Build for all platforms (only works on macos - adjust for linux)
    ```sh
    make build-all
    ```

### Running the app

To run the project locally, use the following command:

```sh
make run
```
this will run "make build" before executing it

## Docker


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

### prebuilt docker image
you can use the prebuilt docker image from github container registry, you can pull it using the following command:

```sh
docker pull ghcr.io/daniel-le97/pocketbase-libsql:latest
```
you can run it using the following command:

```sh
docker run -d -p 8090:8090 --name pocketbase-libsql-container -e TURSO_URL=<your_turso_url> ghcr.io/daniel-le97/pocketbase-libsql:latest
```
if you are using TURSO you need to set the TURSO_AUTH_TOKEN env variable as well, you can do this by adding -e TURSO_AUTH_TOKEN=<your_turso_auth_token> to the docker run command.

```sh
docker run -d -p 8090:8090 --name pocketbase-libsql-container -e TURSO_URL=<your_turso_url> -e TURSO_AUTH_TOKEN=<your_turso_auth_token> ghcr.io/daniel-le97/pocketbase-libsql:latest
```

or you can use the docker-compose file to run it with a local libsql server instance
### Docker compose
- this runs a self hosted libsql server instance and does not use turso
    ```sh
    docker compose up -d
    ```

## Makefile

```
Available targets:
 patch-go-libsql      Patch go-libsql for darwin_amd64
 run                  Run the application based on the current OS
 check-deps           Check if required dependencies (Zig and Go) are installed
 install-zig          Install Zig using ZVM
 release              Create a GitHub release and upload binaries
 build                Build the application for the current OS using the default CC compiler
 zig-build            Build the application using Zig (use this for cross-compilation)
 linux-arm            Build the application for Linux ARM64
 linux-amd            Build the application for Linux AMD64
 darwin-amd           Build the application for macOS AMD64
 darwin-arm           Build the application for macOS ARM64
 build-all            Build the application for all supported platforms
 docker-build-all     Build and push Docker images for all architectures
 docker-build         Build a Docker image for a specific architecture (this copies the binary into the image)
 build-docker         Build the Docker image (this builds the binary within the image)
 docker-compose-up    Start services using Docker Compose
 docker-compose-down  Stop services using Docker Compose
 docker-compose-logs  View logs from Docker Compose services
 docker-login-ghcr    Log in to GitHub Container Registry
 docker-push-ghcr     Push the Docker image to GitHub Container Registry
```

## Notes
currently cross-compiling for darwin and linux only seems to work on a mac device

this does not work for windows yet, as libsql doesn't target it yet check [go-libsql](https://github.com/tursodatabase/go-libsql) for details