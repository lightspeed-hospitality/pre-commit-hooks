#!/usr/bin/env sh
export VERSION=1.9
mkdir -p .cache
pushd .cache

JAVA_VERSION=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([^"]+)"/\1/g')
if [[ ${JAVA_VERSION} == 1.8* ]]; then
    export VERSION=1.7
fi

if [ ! -f google-java-format-${VERSION}-all-deps.jar ]
then
    curl -LJO "https://github.com/google/google-java-format/releases/download/google-java-format-${VERSION}/google-java-format-${VERSION}-all-deps.jar"
    chmod 755 google-java-format-${VERSION}-all-deps.jar
fi
popd

java -jar .cache/google-java-format-${VERSION}-all-deps.jar --aosp --replace "$@"