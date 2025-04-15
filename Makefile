# Basic Makefile Example
.PHONY: help run check-deps linux-arm linux-amd darwin-amd darwin-arm check_and_create_dir build darwin all zig-build install-zig

OUTPUT_BINARY=pb
OUTPUT_DIR=./dist/build
OS=$(shell go env GOOS)
ARCH=$(shell go env GOARCH)
GOOS=$(shell go env GOOS)
GOARCH=$(shell go env GOARCH)
CC_TARGET?=$(GOARCH)-$(GOOS)

# Load .env variables only if we aren't running "make help"
ifneq ($(MAKECMDGOALS),help)
ifneq (,$(wildcard .env))
    include .env
    export $(shell sed 's/=.*//' .env)
endif
endif

# Define ANSI color codes
COLOR_GREEN=\033[0;32m
COLOR_RED=\033[0;31m
COLOR_BLUE=\033[0;34m
COLOR_YELLOW=\033[0;33m
COLOR_WHITE=\033[0;37m
COLOR_RESET=\033[0m



# Define functions for colorful output
define print_info
	echo "$(COLOR_BLUE)[INFO] $(1)$(COLOR_RESET)"
endef

define print_success
	echo "$(COLOR_GREEN)[SUCCESS] $(1)$(COLOR_RESET)"
endef

define print_error
    echo "$(COLOR_RED)[ERROR] $(1)$(COLOR_RESET)"
endef

define print_warn
    echo "$(COLOR_YELLOW)[WARN] $(1)$(COLOR_RESET)"
endef

# Default target: Show help
help:
	@echo "$(COLOR_YELLOW)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(COLOR_BLUE) %-20s$(COLOR_RESET) $(COLOR_WHITE)%s$(COLOR_RESET)\n", $$1, $$2}'

patch-go-libsql: ## Patch go-libsql for darwin_amd64
	@$(call print_info,"Checking if lib/darwin_amd64 exists in go-libsql...")
	@if [ ! -d "$(shell go list -m -f '{{.Dir}}' github.com/tursodatabase/go-libsql)/lib/darwin_amd64" ]; then \
        $(call print_warn,"Directory '$(shell go list -m -f '{{.Dir}}' github.com/tursodatabase/go-libsql)/lib/darwin_amd64' does not exist. Patching..."); \
        if sudo cp -r $(CURDIR)/lib/darwin_amd64 $(shell go list -m -f '{{.Dir}}' github.com/tursodatabase/go-libsql)/lib/; then \
            $(call print_success,"lib/darwin_amd64 copied successfully."); \
        else \
            $(call print_error,"Failed to copy lib/darwin_amd64. Please try running this with sudo 'make patch-go-libsql'."); \
            exit 1; \
        fi; \
    fi

run: build ## Run the application based on the current OS
	$(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH) serve

check-deps: ## Check if required dependencies (Zig and Go) are installed
	@if [ -z "$(shell which zig)" ]; then \
		$(call print_error,Zig not found. Please install Zig first); \
		$(call print_info,You can install Zig using the command: make install-zig); \
		$(call print_info, or please check https://github.com/ziglang/zig/wiki/Install-Zig-from-a-Package-Manager); \
    else \
        $(call print_success, zig is installed at $(shell which zig)); \
    fi
	@if [ -z "$(shell which go)" ]; then \
		$(call print_error, Go not found); \
		$(call print_info, please check https://go.dev/dl/ for installation instructions); \
    else \
        $(call print_success, Go is installed at $(shell which go)); \
    fi

install-zig: ## Install Zig using ZVM
	@if [ -z "$(shell which go)" ]; then \
        $(call print_error,"Go not found, please check https://go.dev/dl/"); \
		exit 1; \
	fi; \
    else \
        go install -ldflags "-s -w" github.com/tristanisham/zvm@latest; \
        zvm install 0.14.0; \
    fi

remove-build-dir:
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		$(call print_warn,Directory '$(OUTPUT_DIR)' exists. Removing it now...); \
		rm -rf $(OUTPUT_DIR); \
		$(call print_success,Directory '$(OUTPUT_DIR)' removed.); \
	fi

check_and_create_dir:
	@if [ ! -d "$(OUTPUT_DIR)" ]; then \
        $(call print_warn,Directory '$(OUTPUT_DIR)' does not exist. Creating it now...); \
        mkdir -p $(OUTPUT_DIR); \
        $(call print_success,Directory '$(OUTPUT_DIR)' created.); \
    fi

# Define variables for the release
GITHUB_REPO=$(GITHUB_USERNAME)/$(DOCKER_IMAGE_NAME)  # Replace with your GitHub username/repo
RELEASE_VERSION=$(shell git describe --tags --abbrev=0)-$(shell date +%Y%m%d%H%M%S)
RELEASE_FILES=$(wildcard $(OUTPUT_DIR)/*)

release: build-all ## Create a GitHub release and upload binaries
	@$(call print_info,"Creating GitHub release $(RELEASE_VERSION)...")
	@if gh release create $(RELEASE_VERSION) $(RELEASE_FILES) --repo $(GITHUB_REPO) --title "Release $(RELEASE_VERSION)" --notes "Automated release of binaries."; then \
        $(call print_success,"Release $(RELEASE_VERSION) created successfully."); \
    else \
        $(call print_error,"Failed to create release. Please check the logs."); \
        exit 1; \
    fi

package: ## Create .zip and .tar.gz archives for each binary
	@$(call print_info,"Packaging binaries into .zip and .tar.gz archives...")
	@for binary in $(wildcard $(OUTPUT_DIR)/*); do \
        base=$$(basename $$binary); \
        zip "$(OUTPUT_DIR)/$$base.zip" "$$binary" && \
        tar -czf "$(OUTPUT_DIR)/$$base.tar.gz" -C "$(OUTPUT_DIR)" "$$base" && \
        $(call print_success,"Packaged $$binary into $$base.zip and $$base.tar.gz"); \
    done


EXTLDFLAGS_DARWIN=-lc -lunwind -fsanitize=undefined \
    -I$(shell xcrun --sdk macosx --show-sdk-path)/usr/include \
    -L$(shell xcrun --sdk macosx --show-sdk-path)/usr/lib \
    -F$(shell xcrun --sdk macosx --show-sdk-path)/System/Library/Frameworks \

EXTLDFLAGS_LINUX=-static -lc -lunwind -fsanitize=undefined

CGO_CFLAGS=-I$(shell go list -m -f '{{.Dir}}' github.com/tursodatabase/go-libsql)/lib

build: check_and_create_dir ## Build the application for the current OS using the default CC compiler
	@$(call print_info,Building Go for $(GOOS)-$(GOARCH)...using $(shell which cc)); \
	if go build -o "$(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)" main.go; then \
        $(call print_success,Build successful. Output binary: $(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)); \
    else \
        $(call print_error,Build failed. Please check the logs.); \
        exit 1; \
    fi; \

zig-build: check_and_create_dir ## Build the application using Zig (use this for cross-compilation)
	@if [ -z "$(shell which zig)" ]; then \
		$(call print_error,"Zig not found. Please install Zig first."); \
    	$(call print_warn,"You can install Zig using the command: make install-zig"); \
        exit 1; \
    fi; \
	if [ "$(GOOS)" = "darwin" ]; then \
		EXTLDFLAGS="$(EXTLDFLAGS_DARWIN)"; \
	else \
		EXTLDFLAGS="$(EXTLDFLAGS_LINUX)"; \
	fi; \
	$(call print_info,"Building with Zig $(shell zig version) for $(GOOS)-$(GOARCH)..."); \
	$(call print_info,"Building for $(GOOS)-$(GOARCH)...using $(shell which zig)"); \
	export CC="zig cc -target $(CC_TARGET)"; \
	export CXX="zig c++ -target $(CC_TARGET)"; \
	export CGO_CFLAGS="$(CGO_CFLAGS)"; \
	export CGO_ENABLED=1; \
	if go build -ldflags "-s -w -extldflags '$$EXTLDFLAGS'" -o "$(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)" main.go; then \
		$(call print_success,"Build successful. Output binary: $(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)"); \
	else \
		$(call print_error,"Build failed. Please check the logs."); \
		exit 1; \
	fi; \


linux-arm: ## Build the application for Linux ARM64
	@$(MAKE) zig-build GOOS=linux GOARCH=arm64 CC_TARGET=aarch64-linux-gnu
linux-amd: ## Build the application for Linux AMD64
	@$(MAKE) zig-build GOOS=linux GOARCH=amd64 CC_TARGET=x86_64-linux-gnu
darwin-amd: patch-go-libsql ## Build the application for macOS AMD64
	@$(MAKE) zig-build GOOS=darwin GOARCH=amd64 CC_TARGET=x86_64-macos
darwin-arm: ## Build the application for macOS ARM64
	@$(MAKE) zig-build GOOS=darwin GOARCH=arm64 CC_TARGET=aarch64-macos


build-all: patch-go-libsql remove-build-dir check_and_create_dir ## Build the application for all supported platforms
	@$(call print_info,"Building for all platforms...")
	@$(MAKE) linux-amd
	@$(MAKE) linux-arm
	@if [ "$(GOOS)" = "darwin" ]; then \
		$(MAKE) darwin-arm; \
		$(MAKE) darwin-amd; \
	fi
	@$(call print_success,"All platforms built successfully at $(OUTPUT_DIR)")
	@$(call print_success,"Output binaries:")

# Docker-related variables
DOCKER_IMAGE_NAME=pocketbase-libsql
DOCKER_TAG=latest
DOCKER_COMPOSE_FILE=docker-compose.yml
DOCKER_REGISTRY=ghcr.io


docker-build-all: ## Build and push Docker images for all architectures
	@$(MAKE) docker-build ARCH=linux/arm64 BINARY=pb-linux-arm64
	@$(MAKE) docker-build ARCH=linux/amd64 BINARY=pb-linux-amd64

docker-build: ## Build a Docker image for a specific architecture (this copies the binary into the image)
	@echo "$(COLOR_BLUE)Building Docker image for $(ARCH) using $(BINARY) with Dockerfile.template...$(COLOR_RESET)"
	@echo "Command: docker buildx build --platform $(ARCH) --build-arg BINARY=$(BINARY) -f Dockerfile.template -t $(DOCKER_IMAGE_NAME):$(subst /,-,$(ARCH)) . --load"
    docker buildx build --platform $(ARCH) --build-arg BINARY=$(BINARY) -f Dockerfile.template -t $(DOCKER_IMAGE_NAME):$(subst /,-,$(ARCH)) . --load

# Build a Docker image
build-docker: ## Build the Docker image (this builds the binary within the image)
	@echo "$(COLOR_BLUE)Building Docker image $(DOCKER_IMAGE_NAME):$(DOCKER_TAG)...$(COLOR_RESET)"
	@if docker build -t $(DOCKER_REGISTRY)/$(GITHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG) .; then \
        echo "$(COLOR_GREEN)Docker image built successfully: $(DOCKER_REGISTRY)/$(GITHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG)$(COLOR_RESET)"; \
    else \
        echo "$(COLOR_RED)Failed to build Docker image. Please check the logs.$(COLOR_RESET)"; \
        exit 1; \
    fi

# Run Docker Compose
docker-compose-up: ## Start services using Docker Compose
	@$(call print_info,Starting services with Docker Compose...)
	@if docker-compose -f $(DOCKER_COMPOSE_FILE) up -d; then \
		$(call print_success,Services started successfully.); \
    else \
		$(call print_error,Failed to start services. Please check the logs.); \
        exit 1; \
    fi

# Stop Docker Compose
docker-compose-down: ## Stop services using Docker Compose
	@$(call print_info,Stopping services with Docker Compose...)
	@if docker-compose -f $(DOCKER_COMPOSE_FILE) down; then \
		$(call print_success,Services stopped successfully.); \
    else \
		$(call print_error,Failed to stop services. Please check the logs.); \
        exit 1; \
    fi

# View Docker Compose logs
docker-compose-logs: ## View logs from Docker Compose services
	@$(call print_info,Fetching logs from Docker Compose services...)
	@docker-compose -f $(DOCKER_COMPOSE_FILE) logs -f

docker-login-ghcr: ## Log in to GitHub Container Registry
	@$(call print_info,Logging in to GitHub Container Registry...)
	@if echo "$(GITHUB_TOKEN)" | docker login ghcr.io -u $(GITHUB_USERNAME) --password-stdin; then \
        $(call print_success,Login successful.); \
    else \
        $(call print_error,Failed to log in to GitHub Container Registry. Please check your token.); \
        exit 1; \
    fi

docker-push-ghcr: docker-login-ghcr ## Push the Docker image to GitHub Container Registry
	@$(call print_info,Pushing Docker image $(DOCKER_IMAGE_NAME):$(DOCKER_TAG) to GHCR...)
	@if docker push ghcr.io/$(GITHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG); then \
        $(call print_success,Docker image pushed successfully to ghcr.io/$(GITHUB_USERNAME)/$(DOCKER_IMAGE_NAME):$(DOCKER_TAG)); \
    else \
        $(call print_error,Failed to push Docker image to GHCR. Please check your credentials and network connection.); \
        exit 1; \
    fi
