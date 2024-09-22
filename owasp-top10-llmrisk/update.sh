#!/bin/sh

# Ensure we're in the root directory of the project
cd "$(dirname "$0")" || exit

echo "Starting update process..."

printf "\nStep 1: Updating URLs\n"
if ! sh scripts/update-urls.sh; then
    echo "Error: update-urls.sh failed"
    exit 1
fi

printf "\nStep 2: Scraping URLs and converting to Markdown\n"
if ! sh scripts/scrape-urls.sh; then
    echo "Error: scrape-urls.sh failed"
    exit 1
fi

printf "\nStep 3: Assembling Markdown files\n"
if ! sh scripts/assemble.sh; then
    echo "Error: assemble.sh failed"
    exit 1
fi

printf "\nStep 4: Cleaning up\n"
rm -rf scripts/output
rm -f scripts/urls.txt

printf "\nUpdate process completed successfully!\n"