#!/usr/bin/env bash
#
# Install Terraform.

set -e

if command -v brew > /dev/null; then
  brew install pyenv
  brew install hashicorp/tap/terraform
fi
