#!/bin/bash

set -e
set -o pipefail
if [ "$DEBUG" = "true" ] ; then set -x ; fi

if ! command -v curl &>/dev/null; then
  echo "curl is not found - cannot run validation"
  exit 1
fi

POLICY_BOT_DOMAIN="${POLICY_BOT_DOMAIN:-policy-bot.lsk.lightspeed.app}"
POLICY_YAML_FILE="${1:-./.policy.yml}"

if ! HTTP_STATUS_CODE="$(curl "https://${POLICY_BOT_DOMAIN}/api/validate" -XPUT -T "${POLICY_YAML_FILE}" -sS -w "%{http_code}" -o /dev/stderr)" ; then
  echo ">>> curl request failed"
  exit 1
fi

# curl will not print a final newline
echo

# Print the status code captured with `-w`
echo ">>> Status Code ${HTTP_STATUS_CODE}"

# Any non-2xx response is an error
if [[ "${HTTP_STATUS_CODE}" -lt 200 ]] || [[ "${HTTP_STATUS_CODE}" -gt 299 ]]; then
  echo ">>> Validation error in policy-bot policy.yml"
  exit 1
fi

echo ">>> Validation successful"
