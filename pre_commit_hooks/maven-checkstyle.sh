#!/usr/bin/env bash

if ! command -v mvn &>/dev/null; then
  >&2 echo "Error: 'mvn' command not found"
  exit 1
fi

mvn checkstyle:check
