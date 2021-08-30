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

java -jar .cache/google-java-format-${FORMATTER_VERSION}-all-deps.jar --aosp --replace @${files_to_format}
