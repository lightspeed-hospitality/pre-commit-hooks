#!/usr/bin/env bash
# Use mvn from path, fall back to mvnw (wrapper)
if command -v mvn &>/dev/null; then
  echo "Running spotless with mvn from path"
  mvn spotless:apply
elif [ -f "./mvnw" ]; then
  echo "Running spotless using maven WRAPPER from path"
  ./mvnw spotless:apply
else
  >&2 echo "Error: Neither 'mvn' nor './mvnw' found (Maven is needed to execute spotless:apply)"
  exit 1
fi
