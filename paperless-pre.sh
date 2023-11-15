#!/usr/bin/env bash
# pdf2pdfocr.py -i "${DOCUMENT_WORKING_PATH}"

# print the first arguemtn to log file if it exists otherwise print the DOCUMENT_WORKING_PATH
echo "file: ${1-:${DOCUMENT_WORKING_PATH}}" >> ~/Workspace/paperless-utils/log.txt

if [ -n "${DOCUMENT_WORKING_PATH}" ]; then
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dBATCH -dQUIET \
        -sOutputFile="${DOCUMENT_WORKING_PATH}" "${DOCUMENT_WORKING_PATH}"
elif [ -n "$1" ]; then
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dBATCH -dQUIET \
        -sOutputFile="${1}" "${1}"

else
    echo "No file specified"
    exit 1
fi
