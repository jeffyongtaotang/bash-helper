#!/usr/bin/env bash

error() {
    echo "Error: " "$@" && exit 1
}

run_checks() {
    # check if curl is installed
    if ! [ -x "$(command -v curl)" ]; then
        error "curl needs to be installed"
    fi

    # check if jq is installed
    if ! [ -x "$(command -v jq)" ]; then
        error "jq needs to be installed"
    fi
}

check_input() {
  if [[ -z $GITHUB_USERNAME ]]; then
      error "Github Username is missing"
  fi

  if [[ -z $GITHUB_TOKEN ]]; then
      error "Github Token is missing"
  fi

  if [[ -z $OWNER ]]; then
      error "Github repo owner is missing"
  fi

  if [[ -z $REPO ]]; then
      error "Github repo name is missing"
  fi
}

http_req() {
    ARGS=$@

    if [[ $VERBOSE_MODE -eq 1 ]]; then
        ARGS=" -v $ARGS"
    fi

    curl -L --silent --write-out 'HTTP_STATUS_CODE:%{http_code}' -H "Accept: application/vnd.github.v3+json" $ARGS
}

http_status() {
    echo "$@" | tr -d '\n' | sed -e 's/.*HTTP_STATUS_CODE://'
}

http_res_body() {
    echo "$@" | sed -e 's/HTTP_STATUS_CODE\:.*//g'
}

help(){
cat << EOF
Usage: get-my-teams-pr [options ...]
Options:
    -u                    Github Username        [sting,required]
    -t, --token           Github PAT             [string, required]
    -O, --owner           Github repo owner      [string, required]
    -R. --repo            Github repo name       [string, required]
    -A, --authors         Github PR Authers      [JSON::string[], optional]
    -h, --help            Display help text
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -u)
        GITHUB_USERNAME=$2
        shift
        ;;
    -t|--token)
        GITHUB_TOKEN=$2
        shift
        ;;
    -O|--owner)
        OWNER=$2
        shift
        ;;
    -R|--repo)
        REPO=$2
        shift
        ;;
    -A|--authors)
        AUTHORS=$2
        shift
        ;;
    --check-branch)
        SHOULD_CHECK_BRANCH=true
        shift
        ;;
    -h|--help)
        help
        exit 0
        ;;
    esac
    shift
  done
}

parse_query(){
  STR="q=is:open+is:pr+repo:$OWNER/$REPO"

  while read -r AUTHOR ; do
      STR+="+author:$AUTHOR"
  done < <(echo "$AUTHORS" | jq -c '.[]' | tr -d '"')

  echo "$STR"
}

retrieve_prs() {
  QUERY=$(parse_query)
  ARGS="-G -u $GITHUB_USERNAME:$GITHUB_TOKEN -X GET --url https://api.github.com/search/issues --data $QUERY"
  RES=$(http_req "$ARGS")
  RESPONSE_BODY=$(http_res_body "$RES")
  STATUS=$(http_status "$RES")

  if ! [[ $STATUS -eq 200 ]]; then
    error "retrieve PRs failed... (Status code: $STATUS)"
  else
    echo "$RESPONSE_BODY"
  fi
}

retrieve_pr() {
  PULL_NUMBER=$1
  ARGS="-u $GITHUB_USERNAME:$GITHUB_TOKEN -X GET --url https://api.github.com/repos/$OWNER/$REPO/pulls/$PULL_NUMBER"

  RES=$(http_req "$ARGS")
  RESPONSE_BODY=$(http_res_body "$RES")
  STATUS=$(http_status "$RES")

  if ! [[ $STATUS -eq 200 ]]; then
    error "retrieve PR failed... (Status code: $STATUS)"
  else
    echo "$RESPONSE_BODY"
  fi 
}

parse_and_print_output() {
  COUNT=$(echo "$1" | jq '.total_count')
  X=0

  printf 'Found %s PRs in \"%s\" author by(or condition): \"%s\"\n\n' "$COUNT" "$OWNER/$REPO" "$AUTHORS"

  while [[ $X -lt $COUNT ]]; do
    ITEM=$(echo "$1" | jq ".items[$X]") && X=$((X+1))

    TITLE=$(echo "$ITEM" | jq ".title")
    AUTHOR=$(echo "$ITEM" | jq ".user.login")
    URL=$(echo "$ITEM" | jq ".html_url")
    PULL_NUMBER=$(echo "$ITEM" | jq ".number")

    if [[ ! -z $SHOULD_CHECK_BRANCH ]]; then
      PR=$(retrieve_pr "$PULL_NUMBER")
      BRANCH=$(echo "$PR" | jq '.head.ref')
      DRAFT=$(echo "$PR" | jq '.draft')

      echo "{\"title\": $TITLE, \"draft\": $DRAFT, \"author\": $AUTHOR, \"branch\": $BRANCH, \"url\": $URL}" | jq && echo ""
    else
      echo "{\"title\": $TITLE, \"author\": $AUTHOR, \"url\": $URL}" | jq && echo ""
    fi

    
  done
}

main() {
    run_checks

    parse_args "$@"

    check_input

    PR_DATA=$(retrieve_prs)

    parse_and_print_output "$PR_DATA"
}

# main
VERBOSE_MODE=${VERBOSE_MODE:-0}
main "$@"