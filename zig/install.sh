#!/usr/bin/env bash
#
# Install Zig.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)
source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Zig'
ZIG_INSTALL_DIR="$HOME/.zig"
# Install jq
source "$DOTFILES_ROOT/jq/install.sh"
# Get desired version
user 'Enter Zig version to install (e.g., 0.15.1, or leave empty for latest master):'
read -r -p '> ' version_tag
# Fetch the download index
info 'Fetching Zig download index'
INDEX_JSON=$(curl -fsSL https://ziglang.org/download/index.json)
# Determine the download URL based on version
if [[ -n "$version_tag" ]]; then
  info "Looking for version $version_tag"
  DOWNLOAD_URL=$(echo "$INDEX_JSON" | jq -r --arg version "$version_tag" '.[$version]."aarch64-macos".tarball // empty')
  if [[ -z "$DOWNLOAD_URL" ]]; then
    fail "Version $version_tag not found or aarch64-macos tarball not available"
  fi
else
  info 'Using latest master build'
  DOWNLOAD_URL=$(echo "$INDEX_JSON" | jq -r '.master."aarch64-macos".tarball // empty')
  if [[ -z "$DOWNLOAD_URL" ]]; then
    fail 'Could not find aarch64-macos tarball for master'
  fi
fi
# Download and extract
info "Downloading Zig from $DOWNLOAD_URL"
TEMP_DIR=$(mktemp -d)
curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/zig.tar.xz"
info 'Extracting Zig'
tar -xf "$TEMP_DIR/zig.tar.xz" -C "$TEMP_DIR"
# Move extracted contents to install directory
ZIG_EXTRACTED=$(find "$TEMP_DIR" -name 'zig-*' -type d | head -1)
mkdir -p "$ZIG_INSTALL_DIR"
rm -rf "${ZIG_INSTALL_DIR:?}"/*
mv "$ZIG_EXTRACTED"/* "$ZIG_INSTALL_DIR/"
# Cleanup
rm -rf "$TEMP_DIR"
success "Zig installed to $ZIG_INSTALL_DIR"
