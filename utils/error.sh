#!/usr/bin/env bash

set -e

error() {
  echo "Error: " "$@" 
}

error "$@"
exit 1