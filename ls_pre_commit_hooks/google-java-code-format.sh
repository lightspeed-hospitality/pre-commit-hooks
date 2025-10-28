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
    # Try direct download URL first (avoids GitHub API pagination and rate limits)
    DIRECT_URL_V="https://github.com/google/google-java-format/releases/download/v${FORMATTER_VERSION}/google-java-format-${FORMATTER_VERSION}-all-deps.jar"
    if ! curl -fSL -o "${FILE_NAME}" "${DIRECT_URL_V}"; then
        # Some releases use a non-v tag: google-java-format-${VERSION}
        DIRECT_URL_GJF="https://github.com/google/google-java-format/releases/download/google-java-format-${FORMATTER_VERSION}/google-java-format-${FORMATTER_VERSION}-all-deps.jar"
        if ! curl -fSL -o "${FILE_NAME}" "${DIRECT_URL_GJF}"; then
            # Fallbacks: query GitHub API for the specific tag, then find the asset URL
            URL=$(curl -fsSL "https://api.github.com/repos/google/google-java-format/releases/tags/v${FORMATTER_VERSION}" \
              | jq -r ".assets[] | select(.name | contains(\"all-deps.jar\")) | .browser_download_url" | head -n1)
            if [ -z "${URL}" ] || ! curl -fSL -o "${FILE_NAME}" "${URL}"; then
                URL=$(curl -fsSL "https://api.github.com/repos/google/google-java-format/releases/tags/google-java-format-${FORMATTER_VERSION}" \
                  | jq -r ".assets[] | select(.name | contains(\"all-deps.jar\")) | .browser_download_url" | head -n1)
                if [ -z "${URL}" ] || ! curl -fSL -o "${FILE_NAME}" "${URL}"; then
                    echo "Failed to download google-java-format ${FORMATTER_VERSION}. Please check the version exists (tried tag v${FORMATTER_VERSION} and google-java-format-${FORMATTER_VERSION})." >&2
                    exit 1
                fi
            fi
        fi
    fi
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
