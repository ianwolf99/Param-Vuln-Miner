#!/bin/bash

# Step 1: Install ParamSpider and required tools (if not already installed)
install_tools() {
  echo "[*] Installing necessary tools..."

  # Install XSStrike for XSS
  if ! command -v xsstrike &> /dev/null; then
    echo "[*] Installing XSStrike..."
    git clone https://github.com/s0md3v/XSStrike.git || exit 1
    cd XSStrike && pip3 install -r requirements.txt && cd ..
  fi

  # Install SQLMap for SQL Injection
  if ! command -v sqlmap &> /dev/null; then
    echo "[*] Installing SQLMap..."
    apt-get install sqlmap || exit 1
  fi

  # Install SSRFire for SSRF
  if ! command -v ssrfire &> /dev/null; then
    echo "[*] Installing SSRFire..."
    git clone https://github.com/0xInfection/SSRFmap.git || exit 1
    cd SSRFmap && pip3 install -r requirements.txt && cd ..
  fi

  # Install Commix for Command Injection
  if ! command -v commix &> /dev/null; then
    echo "[*] Installing Commix..."
    apt-get install commix || exit 1
  fi

  # Install additional tools for LFI, RCE, and file uploads (e.g., Burp Suite extensions)
  if ! command -v lfimap &> /dev/null; then
    echo "[*] Installing LFImap..."
    git clone https://github.com/swisskyrepo/lfimap.git || exit 1
    cd lfimap && pip3 install -r requirements.txt && cd ..
  fi

  if ! command -v wfuzz &> /dev/null; then
    echo "[*] Installing Wfuzz for file uploads..."
    apt-get install wfuzz || exit 1
  fi

  if ! command -v nmap &> /dev/null; then
    echo "[*] Installing Nmap (can be used for RCE)..."
    apt-get install nmap || exit 1
  fi

  echo "[*] All necessary tools installed."
}

# Step 2: Run vulnerability scanning tools based on the file name
run_tools() {
  local file=$1
  local domain=$2

  case "$file" in
    *xss.txt)
      echo "[*] Running XSStrike for XSS on $file..."
      while IFS= read -r url; do
        xsstrike -u "$url" --fuzzer --blind --evade
      done < "$file"
      ;;
    *sqli.txt)
      echo "[*] Running SQLMap for SQL Injection on $file..."
      while IFS= read -r url; do
        sqlmap -u "$url" --batch --level=5 --risk=3 --random-agent --tamper=space2comment,between,modsecurityversioned --technique=BEUST
      done < "$file"
      ;;
    *ssrf.txt)
      echo "[*] Running SSRFire for SSRF on $file..."
      while IFS= read -r url; do
        ssrfire -u "$url" --timeout 10
      done < "$file"
      ;;
    *command-injection.txt)
      echo "[*] Running Commix for Command Injection on $file..."
      while IFS= read -r url; do
        commix --url "$url" --batch --random-agent --technique=TCP --tamper=space2comment
      done < "$file"
      ;;
    *open-redirect.txt)
      echo "[*] Running Open Redirect testing tool on $file..."
      while IFS= read -r url; do
        # Example: You can use `ffuf` or a custom redirect tester tool.
        wfuzz -u "$url" -w wordlist.txt
      done < "$file"
      ;;

    *lfi.txt)
      echo "[*] Running LFImap for Local File Inclusion on $file..."
      while IFS= read -r url; do
        lfimap -u "$url" -a
      done < "$file"
      ;;
    
    *)
      echo "[!] No matching tool for file: $file"
      ;;
  esac
}

# Step 3: Process all domain files for each vulnerability category
process_domains() {
  local domain_files=("$@")

  for domain_file in "${domain_files[@]}"; do
    domain=$(basename "$domain_file" | cut -d'-' -f1)
    echo "[*] Processing domain: $domain"
    
    # Run tools based on the vulnerability file
    run_tools "$domain_file" "$domain"
  done
}

# Main script
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <list of domain files>"
  exit 1
fi

# Step 1: Install necessary tools
install_tools

# Step 2: Process each domain and corresponding vulnerability files
process_domains "$@"

# Final step
echo "[*] Vulnerability testing complete for all domains and files."
