#!/usr/bin/env bash
set -e

VERSION="1.2.0"
ARCH="${1:-amd64}"
BUILD_DIR="dist/deb/overlay_${VERSION}_${ARCH}"

echo "🔨 Building Overlay Debian (.deb) package for ${ARCH}..."

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/DEBIAN"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/usr/lib/systemd/user"

# Compile Linux binary
GOOS=linux GOARCH="${ARCH}" CGO_ENABLED=0 go build -o "${BUILD_DIR}/usr/bin/overlay" ./cmd/overlay

# Copy systemd unit file
cp packaging/systemd/overlay.service "${BUILD_DIR}/usr/lib/systemd/user/overlay.service"

# Generate control file
cat <<EOF > "${BUILD_DIR}/DEBIAN/control"
Package: overlay
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: bogusdeck <bogusdeck@github.com>
Depends: libc6 (>= 2.27)
Recommends: maim, scrot, tesseract-ocr, xclip, wl-clipboard
Description: macOS & Linux AI Assistant & Code HUD
 Overlay is a lightweight floating translucent HUD application for AI assistance,
 screen OCR capture, clipboard problem solving, and dual AI backend routing powered
 by Ollama and Antigravity (agy).
EOF

# Build package using dpkg-deb or fallback directory tarball
mkdir -p dist
if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb --build "${BUILD_DIR}" "dist/overlay_${VERSION}_${ARCH}.deb"
    echo "✅ Created dist/overlay_${VERSION}_${ARCH}.deb"
else
    tar -czf "dist/overlay_${VERSION}_${ARCH}.deb.tar.gz" -C dist/deb "overlay_${VERSION}_${ARCH}"
    echo "✅ Created dist/overlay_${VERSION}_${ARCH}.deb.tar.gz (dpkg-deb not available locally)"
fi
