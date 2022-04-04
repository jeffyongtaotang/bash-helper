#!/usr/bin/env bash

# parseArgs.sh MENU_JSON [...arguemnts]
# parse argument by the JSON format.
# example: 
#   $> parseArgs '{"-t|--tag":"TEST"}' '--tag' 'abc'
#   $> { "TEST": "abc" }

set -e

parse_args() {
  MENU_JSON="$1" && shift;
  RES="{}"

  while [[ $# -gt 0 ]]; do
    KEY="$1"
    VAL="$2"

    [[ -z $(jq <<< "$2" 2>/dev/null) ]] && VAL="\"$2\""

    while IFS='' read -r TAG_NAME; do
      VAR_NAME=$(echo "$MENU_JSON" | jq -r ".$TAG_NAME")
      [[ "$TAG_NAME" =~ $KEY ]] && RES=$(echo "$RES" | jq ". += {\"$VAR_NAME\": $VAL}") && shift;
    done < <(echo "$MENU_JSON" | jq 'keys[]')
    shift;
  done

  echo "$RES"
}

parse_args "$@"
exit 0
