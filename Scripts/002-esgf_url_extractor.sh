#!/bin/bash

# Path to your script
SCRIPT_FILE="ec-earth3-hist.sh"

# Extract the content of the download_files variable
# This sed command finds the start and end markers of the heredoc
file_list_content=$(sed -n '/^download_files="$(cat <<EOF--dataset.file.url.chksum_type.chksum$/,/^EOF--dataset.file.url.chksum_type.chksum$/{
    /EOF--dataset.file.url.chksum_type.chksum$/d
    /^download_files/d
    p
}' "$SCRIPT_FILE")

# Process each line to extract the URL
echo "$file_list_content" | while IFS= read -r line; do
    # Skip empty lines or lines that are not data entries
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi
    # Use awk to extract the URL (the 2nd field when splitting by single quote as delimiter,
    # which becomes the 4th field in awk if FS='\'')
    url=$(echo "$line" | awk -F"'" '{print $4}')
    echo "$url"
done > idm_url_list.txt

echo "URLs extracted to idm_url_list.txt"
