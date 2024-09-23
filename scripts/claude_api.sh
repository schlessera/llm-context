#!/bin/sh

# This script provides functions for interacting with the Claude API.
# It includes a function to check if the API key is set and another to send requests to the API.
# These functions are used by other scripts that need to communicate with Claude.

# Check if CLAUDE_API_KEY is set
check_api_key() {
    if [ -z "$CLAUDE_API_KEY" ]; then
        echo "Error: CLAUDE_API_KEY environment variable is not set."
        exit 1
    fi
}

# Function to send request to Claude API
send_to_claude() {
    prompt="$1"
    # Escape the prompt for JSON
    escaped_prompt=$(printf '%s' "$prompt" | jq -Rsc .)
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

    # Store the response in a file for debugging purposes, using a timestamp in the filename
    timestamp=$(date +%Y%m%d_%H%M%S)
    mkdir -p .debug
    echo "$response" > .debug/claude_response_"$timestamp".json
    
    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "Error: Empty response from Claude API."
        return 1
    fi

    # Extract the content from the response
    content=$(printf '%s\n' "$response" | jq -r '.content[0].text // empty')
    if [ -z "$content" ]; then
        echo "Error: Unable to parse Claude API response."
        echo "Raw response: $response"
        return 1
    fi
    printf '%s\n' "$content"
}