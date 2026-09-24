#!/usr/bin/env bash

set -Eeuo pipefail

readonly EXIT_INVALID_ARGUMENTS=64
readonly EXIT_COMMIT_MESSAGE_FILE_NOT_FOUND=66
readonly EXIT_INVALID_COMMIT_MESSAGE=1
readonly COMMIT_MESSAGE_PATTERN='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([^()]+\))?(!)?: .+$'

main() {
    if (($# != 1)); then
        printf 'Usage: %s <commit-message-file>\n' "$0" >&2
        return "$EXIT_INVALID_ARGUMENTS"
    fi

    local -r commit_message_file=$1
    if [[ ! -f $commit_message_file ]]; then
        printf 'Commit message file not found: %s\n' "$commit_message_file" >&2
        return "$EXIT_COMMIT_MESSAGE_FILE_NOT_FOUND"
    fi

    local subject
    IFS= read -r subject < "$commit_message_file" || true

    if [[ ! $subject =~ $COMMIT_MESSAGE_PATTERN ]]; then
        printf '%s\n' \
            'Invalid commit message.' \
            'Expected Angular format, for example: feat: add login' >&2
        return "$EXIT_INVALID_COMMIT_MESSAGE"
    fi
}

main "$@"
