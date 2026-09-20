.PHONY: all build build-linux deb pacman arch clean install help

BINARY_NAME=overlay
VERSION=1.0.0

all: build

build:
	@echo "🔨 Building overlay..."
	go build -o $(BINARY_NAME) .

build-linux:
	@echo "🔨 Building overlay for Linux..."
	GOOS=linux CGO_ENABLED=0 go build -o $(BINARY_NAME)_linux .

deb:
	@bash ./scripts/build-deb.sh amd64

pacman: arch

arch:
	@bash ./scripts/build-pacman.sh x86_64

install: build
	@echo "🚀 Installing $(BINARY_NAME) to /usr/local/bin..."
	install -d /usr/local/bin
	install -m 755 $(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)

clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(BINARY_NAME) $(BINARY_NAME)_linux dist/

help:
	@echo "Overlay Build & Packaging Commands:"
	@echo "  make build       - Build native binary"
	@echo "  make build-linux - Build Linux binary"
	@echo "  make deb         - Build Debian package (.deb) for apt-get"
	@echo "  make pacman      - Build Arch Linux package (.pkg.tar.zst) for pacman"
	@echo "  make install     - Install binary to /usr/local/bin"
	@echo "  make clean       - Remove built binaries and dist packages"
