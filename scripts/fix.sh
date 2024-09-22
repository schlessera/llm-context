#!/bin/sh

# Check if CLAUDE_API_KEY is set
if [ -z "$CLAUDE_API_KEY" ]; then
    echo "Error: CLAUDE_API_KEY environment variable is not set."
    exit 1
fi

# Check if glow is installed
if ! command -v glow >/dev/null 2>&1; then
    echo "Error: glow is not installed. Please install it to format the output."
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

# Function to send request to Claude API
send_to_claude() {
    prompt="$1"
    # Escape newlines and quotes for JSON, preserving line breaks
    escaped_prompt=$(printf '%s' "$prompt" | awk '{printf "%s\\n", $0}' | sed 's/"/\\"/g')
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
                    \"content\": \"$escaped_prompt\"
                }
            ]
        }")
    
    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "Error: Empty response from Claude API."
        exit 1
    fi

    # Extract the content from the response, escaping all necessary characters for jq
    content=$(printf '%s\n' "$response" | jq -r '.content[0].text // empty')
    if [ -z "$content" ]; then
        echo "Error: Unable to parse Claude API response."
        echo "Raw response: $response"
        exit 1
    fi
    printf '%s\n' "$content"
}

# Process each script
for script in $scripts; do
    echo -n "Checking $script ... "
    
    # Run shellcheck on the script and capture its output
    shellcheck_output=$(shellcheck "$script" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅"
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

Please provide fixes for these issues, explaining each fix. Format your response as a series of suggestions in markdown, each starting with a new heading '## Suggestion: ' followed by the explanation in a separate paragraph and then the fixed code snippet. Output the fixed code snippet as a code block of type 'bash'. Do not include any preceding text or paragraph before the code snippet. The full output will only contain one heading and one paragraph for each suggestion, as well as one code block with the code snippet, no other text. Ensure each suggestion is clearly separated."

    echo ""

    # Send to Claude and get the response
    claude_response=$(send_to_claude "$prompt")
    
    # Check the exit code of Claude's response
    if [ $? -ne 0 ]; then
        echo "Error: Claude API request failed."
        echo "Claude's response: $claude_response"
        exit 1
    fi
    
    # Process each suggestion and code block
    while IFS= read -r suggestion
    do
        # Extract the code block
        code_block=$(echo "$suggestion" | sed 's/¬/\n/g' | sed -n '/```bash/,/```/p' | sed '1d;$d')
        
        # Create temporary files for diff
        temp_original=$(mktemp)
        temp_fixed=$(mktemp)
        
        # Write contents to temporary files
        printf '%s\n' "$script_content" > "$temp_original"
        printf '%s\n' "$code_block" > "$temp_fixed"
        
        # Generate the diff
        diff_output=$(diff -u "$temp_original" "$temp_fixed" | sed '1,2d')
        
        # Clean up temporary files
        rm "$temp_original" "$temp_fixed"
        
        # Prepare the markdown output
        markdown_output=$(cat <<EOF
$(echo "$suggestion" | sed 's/¬/\n/g' | sed '/```bash/,/```/d')

## Diff for this suggestion

\`\`\`diff
$diff_output
\`\`\`
EOF
)

        # Display the suggestion and diff using glow
        echo "$markdown_output" | glow -
        
        # Ask user if they want to apply this fix
        while true; do
            printf "Do you want to apply this fix? (y/n): "
            read -r apply_fix < /dev/tty
            case $apply_fix in
                [Yy]* ) 
                    # Apply the fix
                    printf '%s\n' "$code_block" > "$script"
                    echo "Fix applied to $script"
                    # Update script_content for the next iteration
                    script_content="$code_block"
                    break
                    ;;
                [Nn]* ) 
                    echo "Fix not applied."
                    break
                    ;;
                * ) echo "Please answer y or n.";;
            esac
        done
        
        echo
    done <<EOF
$(echo "$claude_response" | awk '/^## Suggestion:/,/```$/' | sed -e '1h;1!H;$!d;x' -e 's/\n/¬/g' | sed 's/¬## Suggestion:/\n## Suggestion:/g')
EOF

    echo "All suggestions for $script processed."
    echo
done

echo "All scripts processed."