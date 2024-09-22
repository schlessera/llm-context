#!/bin/sh

# Check if CLAUDE_API_KEY is set
if [ -z "$CLAUDE_API_KEY" ]; then
    echo "Error: CLAUDE_API_KEY environment variable is not set."
    exit 1
fi

# Function to get all .sh files in all subfolders
get_all_scripts() {
    find . -type f -name "*.sh"
}

# Determine which scripts to process
if [ $# -eq 0 ]; then
    scripts=$(get_all_scripts)
else
    scripts="$*"
fi

echo "Scripts to process: $scripts"

# Function to send request to Claude API
send_to_claude() {
    prompt="$1"
    # Escape special characters in the prompt for JSON
    escaped_prompt=$(printf '%s' "$prompt" | jq -sRr @json)
    echo "Escaped prompt: $escaped_prompt"
    response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $CLAUDE_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"claude-3-5-sonnet-20240620\",
            \"max_tokens\": 5000,
            \"messages\": [
                {
                    \"role\": \"user\",
                    \"content\": $escaped_prompt
                }
            ]
        }")
    
    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "Error: Empty response from Claude API."
        exit 1
    fi

    echo "Response: $response"
    
    # Extract the content from the response
    echo "$response" | jq -r '.content[0].text'
}

# Process each script
for script in $scripts; do
    echo "Processing $script..."
    
    # Run shellcheck on the script and capture its output
    shellcheck_output=$(shellcheck "$script" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "No issues found for $script. Skipping."
        continue
    fi
    
    # Read the script content
    script_content=$(cat "$script")
    
    # Prepare the prompt for Claude
    prompt="I have a shell script with the following shellcheck issues:

$shellcheck_output

Here's the current content of the script:

\`\`\`bash
$script_content
\`\`\`

Please provide fixes for these issues, explaining each fix. Format your response as a series of suggestions, each starting with 'Suggestion:' followed by the explanation and the fixed code snippet. Output the fixed code snippet as a code block of type 'bash'. Do not add any other code block in the response except for the complete script replacement snippet."

    # Send to Claude and get the response
    claude_response=$(send_to_claude "$prompt")
    
    echo "Claude's suggestions:"
    echo "$claude_response"
    
    # Ask user if they want to apply the fixes
    printf "Do you want to apply these fixes? (y/n): "
    read -r apply_fixes
    
    if [ "$apply_fixes" = "y" ]; then
        # Extract code snippets from Claude's response
        fixed_content=$(echo "$claude_response" | sed -n '/```bash/,/```/p' | sed '1d;$d')
        
        # Apply the fixes
        echo "$fixed_content" > "$script"
        echo "Fixes applied to $script"
    else
        echo "Fixes not applied."
    fi
    
    echo
done

echo "All scripts processed."