#!/usr/bin/env bash

# /cmd/bh.sh
# THe Bash Helper entry point

set -e

main() {
  if [[ -z "${BH_PROJECT_ROOT}" ]]; then
    # shellcheck disable=SC2016
    printf "\"%s\" not found from env\n" '$BH_PROJECT_ROOT' && exit 1
  fi

  RESOLVE_MODULE_PAHT_CMD="${BH_PROJECT_ROOT}/utils/resolveModulePath.sh"

  # ignore lint error here
  set -a; . "${BH_PROJECT_ROOT}/.env"; set +a

  # shellcheck source=../utils/resolveModulePath.sh
  SUB_CMD=$(. "$RESOLVE_MODULE_PAHT_CMD" "$1")

  # rm the 1st argument before execute the sub cmd
  shift;

  # shellcheck source=/dev/null
  . "$SUB_CMD" "$@"
}

main "$@"
exit 0
