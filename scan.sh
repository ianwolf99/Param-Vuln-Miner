#!/bin/bash

# Step 0: Set up virtual environment
setup_virtualenv() {
  echo "[*] Setting up Python virtual environment..."
  
  # Check if virtualenv is installed
  if ! command -v virtualenv &> /dev/null; then
    echo "[*] Installing virtualenv..."
    pip3 install virtualenv || exit 1
  fi
  
  # Create virtual environment in the current directory
  virtualenv paramspider-env || exit 1
  echo "[*] Virtual environment created."

  # Activate virtual environment
  source paramspider-env/bin/activate || exit 1
  echo "[*] Virtual environment activated."
}

# Step 1: Install ParamSpider
install_paramspider() {
  echo "[*] Installing ParamSpider..."
  
  # Check if already installed in virtual environment
  if ! [[ -d "ParamSpider" ]]; then
    git clone https://github.com/devanshbatham/ParamSpider.git || exit 1
    cd ParamSpider || exit 1
    pip3 install -r requirements.txt || exit 1
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
  python3 paramspider.py --domain "$domain" --exclude woff,css,js,png,svg,php,jpg,jpeg,gif --output "$domain-urls.txt"
}

# Step 3: Filter URLs based on specific Google Dorks and save them to categorized files
filter_urls() {
  local domain=$1
  local input_file="$domain-urls.txt"

  echo "[*] Filtering URLs from $input_file for vulnerabilities..."

  # Prepare output files for each vulnerability type
  xss_file="$domain-xss.txt"
  sqli_file="$domain-sqli.txt"
  lfi_file="$domain-lfi.txt"
  ssrf_file="$domain-ssrf.txt"
  redirect_file="$domain-open-redirect.txt"
  rce_file="$domain-rce.txt"
  cmd_injection_file="$domain-command-injection.txt"
  csrf_file="$domain-csrf.txt"
  xxe_file="$domain-xxe.txt"
  upload_file="$domain-file-upload.txt"

  # XSS: Looking for URLs containing parameter input opportunities
  echo "[*] Searching for XSS-prone URLs..."
  grep -E "(\?|&)q=|(\?|&)search=|(\?|&)query=|(\?|&)s=|(\?|&)keywords=" "$input_file" > "$xss_file"

  # SQL Injection: Dorking for SQLi vulnerable patterns
  echo "[*] Searching for SQL Injection-prone URLs..."
  grep -E "(\?|&)id=|(\?|&)cat=|(\?|&)product=|(\?|&)item=|(\?|&)page=" "$input_file" > "$sqli_file"

  # LFI: Looking for Local File Inclusion-prone patterns
  echo "[*] Searching for LFI-prone URLs..."
  grep -E "(\?|&)file=|(\?|&)path=|(\?|&)template=|(\?|&)dir=" "$input_file" > "$lfi_file"

  # SSRF: Identifying SSRF-prone URLs
  echo "[*] Searching for SSRF-prone URLs..."
  grep -E "(\?|&)url=|(\?|&)uri=|(\?|&)redirect=" "$input_file" > "$ssrf_file"

  # Open Redirect: Searching for URLs prone to Open Redirect
  echo "[*] Searching for Open Redirect-prone URLs..."
  grep -E "(\?|&)next=|(\?|&)url=|(\?|&)redir=|(\?|&)return=" "$input_file" > "$redirect_file"

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

# Step 0: Setup virtual environment
#setup_virtualenv

# Step 1: Install ParamSpider if not already installed
install_paramspider

# Step 2: Process domains from the specified file
process_domains "$domain_file"

# Final step
echo "[*] URL collection and filtering complete for all domains."
