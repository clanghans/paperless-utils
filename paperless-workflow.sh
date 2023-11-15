#!/usr/bin/env bash

source "yes_or_no.sh"
source "paperless-config.sh"

# $1: file name to move
function inbox_tagging(){

    if [ -z "$1" ]; then
        echo "inbox_tagging: file name is required"
        exit 1
    fi
    local selected_tags
    local full_path="${PAPERLESS_INBOX_PATH}"

    # print and select tags
    selected_tags=$(jq -r '.[] | select(.model == "documents.tag") | .fields.name' \
        "${PAPERLESS_MANIFEST_PATH}" | fzf --multi --header="Use Shift-Tab for multiselect")

    # Set internal field separator to newline for correct splitting
    IFS=$'\n'
    for tag in $selected_tags; do
        full_path="${full_path}/${tag}"
    done
    mkdir -p "$full_path"
    echo "Created directory: $full_path"

    # move document to inbox
    mv "${filename}" "${full_path}"
}

function process(){
    local date
    local hash
    local hash_long
    local filename

    date=$(date '+%Y-%m-%d')
    hash=$(date '+%Y-%m-%d-%H-%M-%S-%N' | sha256sum)
    hash_long=$(echo "${hash}" | cut -c 1-8)
    filename="${date}-${hash_long}.pdf"

    # scan document
    ./paperless-scan.sh "${filename}"

    yes_or_no "View current document?" "no"
    if [ $? -eq 1 ]; then
        google-chrome "./${filename}" &
    fi

    inbox_tagging "${filename}"
}

function main(){

    # keep physical document?
    yes_or_no "Do you want to keep the physical document?" "no"
    if [ $? -eq 1 ]; then
        #
        # write ASN on document
        #
        yes_or_no "Write ASN on document. Proceed?" "yes"
        if [ $? -ne 1 ]; then
            exit 1
        fi

        #
        # scan document
        #
        process

        #
        # archive document
        #
        echo "Archive document..."
    else
        #
        # scan document
        #
        process

        #
        # trash document
        #
        echo "Trash document..."
    fi
}

main "$@"
