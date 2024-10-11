#!/bin/sh

# This script updates the list of URLs for the OWASP LLM Top 10 Risks.
# It downloads the main page, extracts the URLs for the 10 risk posts,
# and saves them to scripts/urls.txt. The script ensures that exactly
# 10 unique URLs are extracted and saved.

# Source the curl_with_retry helper function
. "$(dirname "$0")/../../scripts/curl_with_retry.sh"

# Download the HTML page with retries
printf "Downloading HTML page... "
if ! curl_with_retry "https://genai.owasp.org/llm-top-10/" "scripts/temp.html"; then
    printf "\nError: Failed to download the HTML page\n" >&2
    exit 1
fi
printf "\n"

# Extract URLs for the 10 risk posts and save them to urls.txt
printf "Extracting URLs... "
if ! grep -oP 'href="\K[^"]*(?=")' scripts/temp.html | 
     grep '/llmrisk/llm[0-9][0-9]' | 
     sort | uniq > scripts/urls.txt; then
    printf "❌\nError: Failed to extract URLs\n" >&2
    exit 1
fi
printf "✅\n"

# Clean up temporary file
rm scripts/temp.html

# Verify that we have exactly 10 URLs
url_count=$(wc -l < scripts/urls.txt)
if [ "$url_count" -ne 10 ]; then
    printf "Error: Expected 10 URLs, but found %d\n" "$url_count" >&2
    exit 1
fi

printf "URLs have been successfully updated in scripts/urls.txt\n"