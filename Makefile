# Basic Makefile Example
.PHONY: dev run check-deps linux-arm linux-amd darwin-amd darwin-arm check_and_create_dir build

dev:
	cd ./ui && bun run dev

run:
	./dist/build/pb-linux-amd64 serve


check-deps:
	@if [ -z "$(shell which zig)" ]; then \
		echo "Zig not found, please check https://github.com/ziglang/zig/wiki/Install-Zig-from-a-Package-Manager"; \
	else \
		echo "Zig is already installed"; \
	fi

	@if [ -z "$(shell which go)" ]; then \
		echo "Go not found, please check https://go.dev/dl/"; \
	else \
		echo "Go is already installed"; \
	fi

	@if [ -z "$(shell which bun)" ]; then \
		echo "bun not found, this is used for ./ui, if you are not developing the frontend, you can ignore this, please check https://bun.sh/docs/installation"; \
	else \
		echo "bun is already installed"; \
	fi

OUTPUT_BINARY=pb
OUTPUT_DIR=./dist/build

check_and_create_dir:
	@if [ ! -d "$(OUTPUT_DIR)" ]; then \
        echo "Directory '$(OUTPUT_DIR)' does not exist. Creating it now..."; \
        mkdir -p $(OUTPUT_DIR); \
        echo "Directory '$(OUTPUT_DIR)' created."; \
    else \
        echo "Directory '$(OUTPUT_DIR)' already exists."; \
    fi

build:
	@echo "Building for $(GOOS)/$(GOARCH)..."; \
	export CC="zig cc -target $(CC_TARGET)"; \
	export CXX="zig c++ -target $(CC_TARGET)"; \
    export CGO_CFLAGS="-I/${GOMODCACHE}/github.com/tursodatabase/go-libsql@v0.0.0-20241113154718-293fe7f21b08"; \
    export CGO_ENABLED=1; \
    go clean; \
    go build -ldflags '-extldflags "-static -lc -lunwind"' -o "$(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)" .; \
    echo "Build successful for $(GOOS)/$(GOARCH). Output binary: $(OUTPUT_DIR)/$(OUTPUT_BINARY)-$(GOOS)-$(GOARCH)"

linux-arm: check_and_create_dir
	@$(MAKE) build GOOS=linux GOARCH=arm64 CC_TARGET=aarch64-linux-gnu

linux-amd: check_and_create_dir
	@$(MAKE) build GOOS=linux GOARCH=amd64 CC_TARGET=x86_64-linux-gnu

darwin-amd: check_and_create_dir
	@$(MAKE) build GOOS=darwin GOARCH=amd64 CC_TARGET=x86_64-darwin

darwin-arm: check_and_create_dir
	@$(MAKE) build GOOS=darwin GOARCH=arm64 CC_TARGET=aarch64-macos-none