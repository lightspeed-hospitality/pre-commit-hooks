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
    # Try both version formats: with and without 'v' prefix
    # Newer releases use 'v' prefix (e.g., v1.32.0), older ones don't (e.g., 1.13.0)
    VERSION_WITH_V="v${FORMATTER_VERSION}"
    VERSION_WITHOUT_V="${FORMATTER_VERSION#v}"  # Remove 'v' if it's already there

    URL=""
    PAGE=1
    MAX_PAGES=5

    # Search through pages until we find the version
    while [ -z "$URL" ] && [ "$PAGE" -le "$MAX_PAGES" ]; do
        echo "Searching for version ${FORMATTER_VERSION} on page ${PAGE}..."

        # Fetch releases JSON once per page
        RELEASES_JSON=$(curl -s "https://api.github.com/repos/google/google-java-format/releases?page=${PAGE}")

        # Try to find the release with either version format
        URL=$(echo "$RELEASES_JSON" \
          | jq -r ".[]|select (.name == \"${VERSION_WITH_V}\" or .name == \"${VERSION_WITHOUT_V}\")|.assets[]| select (.name| contains(\"all-deps.jar\"))|.browser_download_url" \
          | head -n 1)

        if [ -z "$URL" ]; then
            # Check if we got any releases on this page
            RELEASES_ON_PAGE=$(echo "$RELEASES_JSON" | jq -r 'length')
            if [ "$RELEASES_ON_PAGE" = "0" ] || [ "$RELEASES_ON_PAGE" = "null" ]; then
                echo "No more releases found. Version ${FORMATTER_VERSION} not found."
                break
            fi
            PAGE=$((PAGE + 1))
        fi
    done

    if [ -z "$URL" ]; then
        echo "Error: Could not find google-java-format version ${FORMATTER_VERSION}"
        popd > /dev/null
        exit 1
    fi

    echo "Downloading from: ${URL}"
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
