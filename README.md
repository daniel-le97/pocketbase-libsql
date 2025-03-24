# pocketbase-libsql

this is a go project that uses pocketbase as a framework, and uses libsql as a replacement for sqlite

## Prerequisites

### Local Development

To build and run the project locally, you need to have the following installed:

- [Go](https://golang.org/doc/install) (version 1.23.4 or later)
- [Zig](https://ziglang.org/download/) (version 0.13.0 or later)


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

please note this will run "./dist/build/pb-linux-amd64 serve". please change the command to your platform

## Notes
i currently only have this working for linux, for macos i had this working at one point but cant get it working again

this does not work for windows yet, as libsql doesnt target it yet