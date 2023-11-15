#!/usr/bin/env bash

source "yes_or_no.sh"

function main(){
    scan "$1"
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

    if [ -z "$1" ]; then
        # Define the output directory and filenames
        date=$(date '+%Y-%m-%d')
        hash=$(date '+%Y-%m-%d-%H-%M-%S-%N' | sha256sum)
        hash_long=$(echo "${hash}" | cut -c 1-8)

        tmp_dir="/tmp/${hash_long}"
        output_filename="${date}-${hash_long}.pdf"
    else
        tmp_dir="/tmp/$1"
        output_filename="$1"
    fi

    mkdir -p "${tmp_dir}"

    scan_brother "${tmp_dir}" 2 1

    # Count the number of scanned pages
    # add one to amount to get the correct amount of pages
    amount=$(find "${tmp_dir}" -type f -name 'out*.tif' | wc -l)
    amount=$((amount*2))

    # Prompt the user for scanning the back side
    yes_or_no "Do you want to scan the back side of the pages?" "yes"
    if [ $? -eq 1 ]; then
        scan_brother "${tmp_dir}" -2 ${amount}
    fi

    # Combine scanned images with back side in reverse order
    echo "Combining scanned images..."
    convert "${tmp_dir}/out*.tif" "${tmp_dir}/${output_filename}"

    # Optionally, perform post-processing with Ghostscript (e.g., optimize PDF)
    # This step is optional but recommended for better PDF quality and smaller file size.
    echo "Optimizing PDF..."
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dBATCH -dQUIET \
        -sOutputFile="${output_filename}" "${tmp_dir}/${output_filename}"

    # DEBUG - display the PDF
    # google-chrome "${output_filename}" &

    echo "filename: ${output_filename}"
}

validate
main "$@"
