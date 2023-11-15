#!/usr/bin/env bash

# $1: message
# $2: default value
# return 0 if no, 1 if yes
function yes_or_no(){
    if [ -z "$1" ]; then
        echo "yes_or_no: message is required"
        exit 1
    fi

    local question=$1
    local default=$2
    local default_string
    local answer

    if [ -n "$default" ]; then
        if [ "$default" = "yes" ]; then
            default_string="Y/n"
        elif [ "$default" = "no" ]; then
            default_string="y/N"
        fi
    fi

    # Loop until a valid answer is provided
    while true; do
        read -rp "${question} ${default_string}: " answer
        case ${answer} in
            [Yy]* ) return 1;;  # Return 1 for "yes"
            [Nn]* ) return 0;;  # Return 0 for "no"
            * )
                if [ -n "${default}" ]; then
                    if [ "${default}" = "yes" ]; then
                        return 1
                    elif [ "${default}" = "no" ]; then
                        return 0
                    fi
                else
                    echo "Please answer yes or no."
                fi;;
        esac
    done
}
