#!/usr/bin/env bash

# resolve-module-path.sh
# private utils script to resolve scriptes reletive path by the "module.json"

set -e

ERROR_CMD="${BH_PROJECT_ROOT}/utils/error.sh"

main() {
  MODULE_JSON=$(cat "${BH_PROJECT_ROOT}/modules.json")

  CMD_PATH=$(echo "$MODULE_JSON" | jq -r ".$1.reletivePath")
  # shellcheck source=./error.sh
  [[ "$CMD_PATH" == "null" ]] && (. "$ERROR_CMD" "Command not found.") || CMD_PATH="${BH_PROJECT_ROOT}/$CMD_PATH"

  echo "$CMD_PATH"
}

main "$@"

exit 0
