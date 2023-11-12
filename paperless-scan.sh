#!/usr/bin/env bash

function main(){
    # single|double|loop|ask
    local COMMAND_MODE="ask"
    local POSITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                COMMAND_MODE="$2"
                shift # past argument
                shift # past value
                ;;
            -*|--*)
                echo "Unknown option $1"
                exit 1
                ;;
            *)
                POSITIONAL_ARGS+=("$1") # save positional arg
                shift # past argument
                ;;
        esac
    done

    if [ "${COMMAND_MODE}" == "loop" ]; then
        local exit_loop=false

        while [ "$exit_loop" = false ]
        do
            scan

            # Ask the user if they want to exit the loop
            read -rp "Do you want to exit the loop? (yes/no): " choice

            # default is no
            case "$choice" in
                [Yy] | [Yy][Ee][Ss] )
                    exit_loop=true
                    ;;
                [Nn] | [Nn][Oo] | * )
                    exit_loop=false
                    ;;
            esac
        done
    fi

}

PAPERLESS_CONFIG_PATH="$HOME/.config/paperless"
PAPERLESS_EXPORT_PATH="${PAPERLESS_CONFIG_PATH}/export"
PAPERLESS_HOME_PATH="$HOME/paperless"
PAPERLESS_CONSUME_PATH="${PAPERLESS_HOME_PATH}/consume"

function get_paperless_tags(){
    # Define the path to the JSON file
    _file="manifest.json"

    # Using jq to extract elements where model is 'documents.tag'
    jq '.[] | select(.model == "documents.tag")' $FILE_PATH
}

function validate(){
    # Check if scanimage is installed
    if ! command -v scanimage &> /dev/null; then
        echo "scanimage could not be found. Please install the sane-utils package."
        exit 1
    fi

    # Check if convert is installed
    if ! command -v convert &> /dev/null; then
        echo "convert could not be found. Please install the imagemagick package."
        exit 1
    fi

    # Check if Ghostscript is installed
    if ! command -v gs &> /dev/null; then
        echo "gs could not be found. Please install the ghostscript package."
        exit 1
    fi
}

# $1: output folder
# $2: batch increment
# $3: batch start
function scan_brother(){

    local output_dir="$1"
    local batch_increment="$2"
    local batch_start="$3"

    while true; do
        scanimage --source ADF --mode gray --contrast 100% -d 'airscan:w1:Brother MFC-L2700DW series' --batch="${output_dir}/out%d.tif" \
            --batch-increment="${batch_increment}" --batch-start="${batch_start}" --format=tiff

        result=$?
        echo "Result: $result"
        # check error code
        if [ $result -eq 0 ] || [ $result -eq 7 ]; then
            break
        fi
    done

}

function scan(){
    # Define the output directory and filenames
    date=$(date '+%Y-%m-%d')
    hash=$(date '+%Y-%m-%d-%H-%M-%S-%N' | sha256sum)
    hash_long=$(echo "${hash}" | cut -c 1-8)
    # hash_short=$(echo "${hash}" | cut -c 1-4)

    output_dir="${hash_long}"
    output_filename="${date}-${hash_long}.pdf"

    mkdir -p "$output_dir"

    scan_brother "${output_dir}" 2 1

    # Count the number of scanned pages
    # add one to amount to get the correct amount of pages
    amount=$(find "$output_dir" -type f -name 'out*.tif' | wc -l)
    amount=$((amount*2))

    # Prompt the user for scanning the back side
    read -rp "Do you want to scan the back side of the pages? (Y/n): " scan_back

    # convert scan_back to lowercase with awk
    # Default value is 'y'
    scan_back=$(echo "${scan_back:-y}" | awk '{print tolower($0)}')

    # Check if the user wants to scan the back side
    if [ "${scan_back}" == "y" ]; then
        scan_brother "${output_dir}" -2 ${amount}
    fi

    # Combine scanned images with back side in reverse order
    echo "Combining scanned images..."
    convert "${output_dir}/out*.tif" "${output_dir}/${output_filename}"

    # Optionally, perform post-processing with Ghostscript (e.g., optimize PDF)
    # This step is optional but recommended for better PDF quality and smaller file size.
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dBATCH -dQUIET -sOutputFile="${output_filename}" "${output_dir}/${output_filename}"

    # DEBUG - display the PDF
    # google-chrome "${output_filename}" &
}

validate
main "$@"
