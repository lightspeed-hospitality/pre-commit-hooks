#!/usr/bin/env bash

# Try to use mvnw but fall back to mvn if not found
if [ -f "mvnw" ]; then
  cmd="./mvnw"
else
  if ! command -v mvn &>/dev/null; then
    >&2 echo "Error: neither 'mvnw' script nor 'mvn' command are found"
    exit 1
  fi
  cmd="mvn"
fi

${cmd} checkstyle:check
