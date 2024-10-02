#!/bin/bash

# Check if the correct number of arguments is provided
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <url_file> <referer> <via>"
    exit 1
fi

# Assign the arguments to variables
url_file="$1"
referer="$2"
via="$3"

# Check if the required files exist
if [[ ! -f "all_attacks.txt" ]]; then
    echo "Error: all_attacks.txt not found!"
    exit 1
fi

if [[ ! -f "$url_file" ]]; then
    echo "Error: $url_file not found!"
    exit 1
fi

# Set User-Agent rotation file
ua_file="useragents.txt"

# Set proxy (optional)
proxy="http://127.0.0.1:8080"

# Custom headers (modify as needed)
custom_headers=(
    "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    "Content-Type: application/x-www-form-urlencoded"
    "X-Forwarded-For: 127.0.0.1"
    "X-Real-IP: 127.0.0.1"
    "X-Remote-IP: 127.0.0.1"
    "X-Remote-Addr: 127.0.0.1"
    "X-Client-IP: 127.0.0.1"
    "Cache-Control: no-cache"
    "Pragma: no-cache"
    "Sec-Fetch-Dest: document"
    "Sec-Fetch-Mode: navigate"
    "Sec-Fetch-Site: same-origin"
    "Sec-Fetch-User: ?1"
)

# Loop through each URL in the provided file
while read -r url; do
    echo "Running ffuf against: $url"
    
    # Rotate User-Agent
    ua=$(shuf -n 1 "$ua_file")
    
    # Prepare header arguments for ffuf
    header_args=()
    for header in "${custom_headers[@]}"; do
        header_args+=("-H" "$header")
    done
    header_args+=("-H" "User-Agent: $ua")
    header_args+=("-H" "Referer: $referer")
    header_args+=("-H" "Via: $via")

    # Execute ffuf with the specified parameters
    ffuf -c \
        -w all_attacks.txt \
        -u "$url" \
        -fc 404,500 \
        -x "$proxy" \
        "${header_args[@]}" \
        -rate 10 \
        -timeout 5
    
done < "$url_file"
