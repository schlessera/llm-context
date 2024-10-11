#!/bin/sh

# Function to load and process prompts
load_prompt() {
    prompt_file="$1"
    shift
    prompt_path="$(dirname "$0")/../prompts/$prompt_file"

    # Check if the prompt file exists
    if [ ! -f "$prompt_path" ]; then
        echo "Error: Prompt file '$prompt_path' not found." >&2
        return 1
    fi

    # Read the prompt file
    prompt=$(cat "$prompt_path")

    # Replace placeholders with arguments using awk
    i=1
    for arg in "$@"; do
        # Use awk to replace the placeholder
        prompt=$(printf '%s\n' "$prompt" | awk -v repl="$arg" "{gsub(/\{\{\{$i\}\}\}/, repl)}1")
        i=$((i + 1))
    done

    # Output the processed prompt
    printf '%s\n' "$prompt"
}
