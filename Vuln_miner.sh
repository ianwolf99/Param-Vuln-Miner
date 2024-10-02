#!/bin/bash

# Step 0: Set up virtual environment (optional)
setup_virtualenv() {
  echo "[*] Setting up Python virtual environment..."

  # Check if virtualenv is installed
  if ! command -v virtualenv &> /dev/null; then
    echo "[*] Installing virtualenv..."
    pip3 install virtualenv || { echo "[!] Failed to install virtualenv"; return 1; }
  fi

  # Create virtual environment in the current directory
  virtualenv paramspider-env || { echo "[!] Failed to create virtual environment"; return 1; }
  echo "[*] Virtual environment created."

  # Activate virtual environment
  source paramspider-env/bin/activate || { echo "[!] Failed to activate virtual environment"; return 1; }
  echo "[*] Virtual environment activated."
}

# Step 1: Install ParamSpider
install_paramspider() {
  echo "[*] Installing ParamSpider..."

  # Check if already installed in virtual environment
  if ! [[ -d "ParamSpider" ]]; then
    git clone https://github.com/devanshbatham/ParamSpider.git || { echo "[!] Failed to clone ParamSpider"; return 1; }
    cd ParamSpider || { echo "[!] Failed to change directory to ParamSpider"; return 1; }
    pip3 install -r requirements.txt || { echo "[!] Failed to install requirements"; return 1; }
    cd ..
    echo "[*] ParamSpider installed successfully!"
  else
    echo "[*] ParamSpider is already installed."
  fi
}

# Step 2: Run ParamSpider for a domain
run_paramspider() {
  local domain=$1
  echo "[*] Running ParamSpider on domain: $domain"

  # Ensure output directory exists
  mkdir -p output

  # Run ParamSpider and output to the 'output' directory
  python3 paramspider.py --domain "$domain" --exclude wootf,woff,css,js,png,svg,jpg,jpeg,gif.mp4 --output "output/$domain-urls.txt" || {
    echo "[!] ParamSpider failed for $domain. Continuing..."
    return 1
  }

  # Check if output file exists
  if [ ! -f "output/$domain-urls.txt" ]; then
    echo "[!] Error: ParamSpider did not generate the output file for $domain. Continuing..."
    return 1
  fi
}

# Step 3: Filter URLs based on specific Google Dorks and save them to categorized files
filter_urls() {
  local domain=$1
  local input_file="output/$domain-urls.txt"

  echo "[*] Filtering URLs from $input_file for vulnerabilities..."

  # Ensure the input file exists before proceeding
  if [ ! -f "$input_file" ]; then
    echo "[!] Error: Input file $input_file not found for $domain. Skipping..."
    return 1
  fi

  # Prepare output files for each vulnerability type
  xss_file="output/$domain-xss.txt"
  sqli_file="output/$domain-sqli.txt"
  lfi_file="output/$domain-lfi.txt"
  ssrf_file="output/$domain-ssrf.txt"
  redirect_file="output/$domain-open-redirect.txt"
  rce_file="output/$domain-rce.txt"
  cmd_injection_file="output/$domain-command-injection.txt"
  csrf_file="output/$domain-csrf.txt"
  xxe_file="output/$domain-xxe.txt"
  upload_file="output/$domain-file-upload.txt"

  # XSS: Looking for URLs containing parameter input opportunities
  echo "[*] Searching for XSS-prone URLs..."
  grep -E "(\?|&)q=|(\?|&)search=|(\?|&)query=|(\?|&)s=|(\?|&)keywords=" "$input_file" > "$xss_file"

  # SQL Injection: Dorking for SQLi vulnerable patterns
  echo "[*] Searching for SQL Injection-prone URLs..."
  grep -E "(\?|&)id=|(\?|&)cat=|(\?|&)product=|(\?|&)item=|(\?|&)page=" "$input_file" > "$sqli_file"

  # LFI: Looking for Local File Inclusion-prone patterns
  echo "[*] Searching for LFI-prone URLs..."
  grep -E "(\?|&)file=|(\?|&)path=|(\?|&)template=|(\?|&)dir=|(\?|&)include=|(\?|&)inc=|(\?|&)load=|(\?|&)view=|(\?|&)read=|(\?|&)open=|(\?|&)show=|(\?|&)doc=|(\?|&)document=|(\?|&)page=|(\?|&)pg=|(\?|&)p=" "$input_file" > "$lfi_file"
  

  # SSRF: Identifying SSRF-prone URLs
  echo "[*] Searching for SSRF-prone URLs..."
  grep -E "(\?|&)url=|(\?|&)uri=|(\?|&)redirect=" "$input_file" > "$ssrf_file"

  # Open Redirect: Searching for URLs prone to Open Redirect
  #echo "[*] Searching for Open Redirect-prone URLs..."
  #grep -E "(\?|&)next=|(\?|&)url=|(\?|&)redir=|(\?|&)return=" "$input_file" > "$redirect_file"

  echo "[*] Searching for Open Redirect-prone URLs..."
  grep -E "(\?|&)next=|(\?|&)url=|(\?|&)redir=|(\?|&)return=|(\?|&)redirectUrl=|(\?|&)redirUrl=|(\?|&)src=|(\?|&)r=" "$input_file" > "$redirect_file"

  # RCE (Remote Code Execution): Looking for potential RCE-prone parameters
  echo "[*] Searching for RCE-prone URLs..."
  grep -E "(\?|&)cmd=|(\?|&)exec=|(\?|&)command=|(\?|&)execute=" "$input_file" > "$rce_file"

  # Command Injection: Searching for command injection-prone parameters
  echo "[*] Searching for Command Injection-prone URLs..."
  grep -E "(\?|&)cmd=|(\?|&)shell=|(\?|&)command=" "$input_file" > "$cmd_injection_file"

  # CSRF: Identifying CSRF-prone URLs
  echo "[*] Searching for CSRF-prone URLs..."
  grep -E "(\?|&)csrf_token=|(\?|&)token=|(\?|&)auth=" "$input_file" > "$csrf_file"

  # XXE: Looking for XXE-prone URLs
  echo "[*] Searching for XXE-prone URLs..."
  grep -E "(\?|&)xml=|(\?|&)data=" "$input_file" > "$xxe_file"

  # File Upload: Looking for unvalidated file upload
  echo "[*] Searching for File Upload-prone URLs..."
  grep -E "(\?|&)upload=|(\?|&)file=|(\?|&)image=" "$input_file" > "$upload_file"

  echo "[*] URLs categorized and saved to respective files."
}

# Step 4: Process domains from a file
process_domains() {
  local domain_file=$1

  # Loop through each domain in the file
  while IFS= read -r domain || [[ -n "$domain" ]]; do
    echo "[*] Processing domain: $domain"

    # Run ParamSpider and filter URLs
    run_paramspider "$domain"
    filter_urls "$domain"

    echo "[*] Finished processing domain: $domain"
  done < "$domain_file"
}

# Main script
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domain_file>"
  exit 1
fi

domain_file=$1

# Step 1: Install ParamSpider if not already installed
install_paramspider

# Step 2: Process domains from the specified file
process_domains "$domain_file"

# Final step
echo "[*] URL collection and filtering complete for all domains."
