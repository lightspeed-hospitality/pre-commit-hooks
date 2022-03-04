#!/usr/bin/env bash
FORMATTER_VERSION=1.13.0

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

FILE_NAME="google-java-format-${FORMATTER_VERSION}-all-deps.jar"

if [ ! -f "${FILE_NAME}" ]
then
    URL=$(curl "https://api.github.com/repos/google/google-java-format/releases" \
      | jq -r ".[]|select (.name == \"${FORMATTER_VERSION}\")|.assets[]| select (.name| contains(\"all-deps.jar\"))|.browser_download_url")
    curl -LJO -o "${FILE_NAME}" "${URL}"
    chmod 755 "${FILE_NAME}"
fi
popd > /dev/null
echo "Using formatter version ${FORMATTER_VERSION}"

JAVA_VERSION=$(java -version 2>&1 | grep -i version | sed -E 's/.*version "([^"]+)".*/\1/; 1q')
case "${JAVA_VERSION}" in
    1.8.*)
    MODULE_OPTIONS=""
    ;;
    *)
    MODULE_OPTIONS="  --add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"
    MODULE_OPTIONS+=" --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED"
    MODULE_OPTIONS+=" --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED"
    MODULE_OPTIONS+=" --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED"
    MODULE_OPTIONS+=" --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED"
    ;;
esac
java ${MODULE_OPTIONS} -jar .cache/google-java-format-${FORMATTER_VERSION}-all-deps.jar --aosp --replace @${files_to_format}
