# Go Project

This is a Go project that requires Go and Zig installed if building locally. Alternatively, you can use Docker to build and run the project.

## Prerequisites

### Local Development

To build and run the project locally, you need to have the following installed:

- [Go](https://golang.org/doc/install) (version 1.23.4 or later)
- [Zig](https://ziglang.org/download/) (version 0.13.0 or later)

### Docker

If you prefer to use Docker, ensure you have Docker installed on your machine. You can download and install Docker from [here](https://www.docker.com/get-started).

## Installation

### Local Installation

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/yourproject.git
    cd yourproject
    ```

2. Install dependencies:

    ```sh
    make install-deps
    ```

### Docker Installation

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/yourproject.git
    cd yourproject
    ```

2. Build the Docker image:

    ```sh
    docker build -t yourproject .
    ```

## Usage

### Local Usage

To run the project locally, use the following command:

```sh
go run main.go
```