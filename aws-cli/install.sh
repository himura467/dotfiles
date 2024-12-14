#!/usr/bin/env bash
#
# Install AWS CLI.

set -e

if ! command -v aws > /dev/null; then
  curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
  sudo installer -pkg AWSCLIV2.pkg -target /
fi
