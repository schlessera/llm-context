#!/bin/sh

# Download the HTML page
if ! curl -s https://genai.owasp.org/llm-top-10/ > scripts/temp.html; then
    printf "Error: Failed to download the HTML page\n" >&2
    exit 1
fi

# Extract URLs for the 10 risk posts and save them to urls.txt
if ! grep -oP 'href="\K[^"]*(?=")' scripts/temp.html | 
     grep '/llmrisk/llm[0-9][0-9]' | 
     sort | uniq > scripts/urls.txt; then
    printf "Error: Failed to extract URLs\n" >&2
    exit 1
fi

# Clean up temporary file
rm scripts/temp.html

# Verify that we have exactly 10 URLs
url_count=$(wc -l < scripts/urls.txt)
if [ "$url_count" -ne 10 ]; then
    printf "Error: Expected 10 URLs, but found %d\n" "$url_count" >&2
    exit 1
fi

printf "URLs have been successfully updated in scripts/urls.txt\n"