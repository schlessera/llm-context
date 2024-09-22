#!/bin/sh

# This script assembles the OWASP LLM Top 10 Risks document from individual markdown files.
# It combines the content of 10 separate markdown files (llm01.md to llm10.md) into a single output file.
# The script adds a main heading, a source reference, and a last updated timestamp to the final document.

output_file="owasp-llm-top-10-risks.md"

# Start with the main heading
printf "# OWASP LLM Top 10 Risks\n\n" > "$output_file"
printf "> Scraped from [https://genai.owasp.org/llm-top-10/](https://genai.owasp.org/llm-top-10/)\n" >> "$output_file"
printf "> Last updated: %s\n" "$(date)" >> "$output_file"

# Loop through the markdown files in numerical order
for i in $(seq -f "%02g" 1 10)
do
    input_file="scripts/output/llm${i}.md"
    
    if [ -f "$input_file" ]; then
        printf "Processing %s\n" "$input_file"
        
        # Add a newline before appending each file
        printf "\n" >> "$output_file"
        
        # Append the content of each file
        if ! cat "$input_file" >> "$output_file"; then
            printf "Error: Failed to append %s\n" "$input_file" >&2
            exit 1
        fi
    else
        printf "Warning: %s not found\n" "$input_file" >&2
    fi
done

printf "Assembly complete. Output file: %s\n" "$output_file"