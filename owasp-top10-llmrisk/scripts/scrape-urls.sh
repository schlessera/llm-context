#!/bin/sh

# This script scrapes content from URLs listed in scripts/urls.txt.
# It fetches HTML content from each URL, converts it to markdown format,
# and saves both HTML and markdown versions in the scripts/output directory.
# The script also extracts and includes the post title in the markdown files.

# Check if urls.txt exists
if [ ! -f scripts/urls.txt ]; then
    printf "Error: scripts/urls.txt not found\n" >&2
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p scripts/output

# Read URLs from urls.txt and process each one
while IFS= read -r url
do
    # Extract the HTML filename from the URL
    filename_html=$(echo "$url" | sed -E 's/.*\/(llm[0-9]{2}).*/\1.html/')
    
    printf "Fetching %s and saving to %s ... " "$url" "$filename_html"

    # Use curl to fetch the URL
    if curl -s "$url" > "scripts/output/$filename_html"; then
        printf "✅\n"
    else
        printf "❌\n" >&2
        continue
    fi

    # Fetch the WordPress post title from the HTML file.
    post_title=$(grep -oP '<title>\K[^<]+' "scripts/output/$filename_html")

    # Extract the markdown filename from the URL
    filename_md=$(echo "$url" | sed -E 's/.*\/(llm[0-9]{2}).*/\1.md/')
    
    printf "Converting %s to %s ... " "$filename_html" "$filename_md"

    # Add the post title as a level 2 heading to the markdown file.
    printf "## %s\n\n" "$post_title" > "scripts/output/$filename_md"

    # Use html2md to fetch and convert the URL to markdown.
    # Go for the selector ".xpro-elementor-content" as we are dealing with an Elementor site.
    # Strip out ".sharedaddy" and ".jp-relatedposts", as these are appended to the main content.
    if html2md -G -i "scripts/output/$filename_html" -s ".xpro-elementor-content" -x ".sharedaddy" -x ".jp-relatedposts" >> "scripts/output/$filename_md"; then
        printf "✅\n"
    else
        printf "❌\n" >&2
    fi
    
done < scripts/urls.txt

printf "All URLs have been processed. Markdown files are in the 'scripts/output' directory.\n"