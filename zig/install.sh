#!/usr/bin/env bash
#
# Install Zig.

set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")"/..; pwd)

source "$DOTFILES_ROOT/lib/logger.sh"

info 'Installing Zig'

if ! command -v zig > /dev/null; then
  if ! command -v brew > /dev/null; then
    user 'Homebrew not found. Would you like to install Homebrew first? (y/n)'
    read -r -p '> ' install_brew

    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
      source "$DOTFILES_ROOT/homebrew/install.sh"
      source "$DOTFILES_ROOT/homebrew/path.zsh"
    else
      fail 'Homebrew is required to install Zig dependencies.'
    fi
  fi

  # Clone Zig repository to home directory
  ZIG_REPO="$HOME/zig"
  if [[ ! -d "$ZIG_REPO" ]]; then
    info 'Cloning Zig repository'
    git clone https://github.com/ziglang/zig.git "$ZIG_REPO"
    cd "$ZIG_REPO"
  else
    info 'Zig repository already exists, updating'
    cd "$ZIG_REPO"
    git fetch --tags
  fi

  # Get desired version tag
  user 'Enter Zig version tag to build (e.g., 0.15.1, or leave empty for latest):'
  read -r -p '> ' version_tag

  if [[ -n "$version_tag" ]]; then
    info "Checking out version $version_tag"
    git checkout "$version_tag"
  else
    info 'Using latest master branch'
    git checkout master
    git pull
  fi

  # Determine required LLVM version from cmake/Findllvm.cmake
  if [[ -f 'cmake/Findllvm.cmake' ]]; then
    llvm_version=$(grep -oE 'expected LLVM [0-9]+' cmake/Findllvm.cmake | head -1 | grep -oE '[0-9]+')
  fi

  info 'Installing build dependencies (CMake, LLVM, LLD)'
  brew install cmake llvm@$llvm_version lld@$llvm_version

  # Build from source
  info 'Building Zig from source'
  mkdir build
  cd build
  cmake .. -DZIG_STATIC_LLVM=ON -DZIG_STATIC_ZSTD=ON -DCMAKE_PREFIX_PATH="$(brew --prefix llvm@$llvm_version);$(brew --prefix lld@$llvm_version);$(brew --prefix zstd)"
  make install

  success 'Zig installed'
else
  success 'Zig is already installed'
fi