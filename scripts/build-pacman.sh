#!/usr/bin/env bash
set -e

VERSION="1.2.0"
ARCH="${1:-x86_64}"
BUILD_DIR="dist/pacman/overlay-${VERSION}-${ARCH}"

echo "🔨 Building Overlay Pacman (.pkg.tar.zst) package for Arch Linux (${ARCH})..."

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/usr/lib/systemd/user"

# Compile Linux binary
GOOS=linux CGO_ENABLED=0 go build -o "${BUILD_DIR}/usr/bin/overlay" ./cmd/overlay

# Copy systemd unit file
cp packaging/systemd/overlay.service "${BUILD_DIR}/usr/lib/systemd/user/overlay.service"

mkdir -p dist
if command -v makepkg >/dev/null 2>&1; then
    makepkg -f
    mv overlay-*.pkg.tar.zst dist/ 2>/dev/null || true
    echo "✅ Created Pacman package in dist/"
else
    tar -czf "dist/overlay-${VERSION}-1-${ARCH}.pkg.tar.gz" -C dist/pacman "overlay-${VERSION}-${ARCH}"
    echo "✅ Created dist/overlay-${VERSION}-1-${ARCH}.pkg.tar.gz (makepkg fallback for non-Arch environments)"
fi
