#!/usr/bin/env bash
FORMATTER_VERSION=1.9

mkdir -p .cache
pushd .cache > /dev/null

files_to_format="$(mktemp)"
formatter_args=()
for arg in "$@" ; do
    case "$arg" in
	--formatter-version=*)
	    FORMATTER_VERSION="$(echo $arg| sed 's/.*=//g')"
	;;
	*)
	    echo "$arg" >> "${files_to_format}"
	;;
    esac
done

if [ ! -f google-java-format-${FORMATTER_VERSION}-all-deps.jar ]
then
    curl -LJO "https://github.com/google/google-java-format/releases/download/google-java-format-${FORMATTER_VERSION}/google-java-format-${FORMATTER_VERSION}-all-deps.jar"
    chmod 755 google-java-format-${FORMATTER_VERSION}-all-deps.jar
fi
popd > /dev/null
echo "Using formatter version ${FORMATTER_VERSION}"

java -jar .cache/google-java-format-${FORMATTER_VERSION}-all-deps.jar --aosp --replace @${files_to_format}
