arjun -q -u target -oT arjun && cat arjun | awk -F'[?&]' '{baseUrl=$1; for(i=2; i<=NF; i++) {split($i, param, "="); print baseUrl "?" param[1] "="}}' | kxss
