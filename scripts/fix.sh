#!/bin/sh

# This script automates the process of fixing shellcheck issues in shell scripts.
# It uses the Claude API to generate suggestions for fixing shellcheck warnings and errors.
# The script then applies these fixes interactively, allowing the user to review and approve each change.

# Source the Claude API functions
# shellcheck source=./claude_api.sh
. "$(dirname "$0")/claude_api.sh"

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

# Check if CLAUDE_API_KEY is set
check_api_key

# Process each script
for script in $scripts; do
    printf "Checking %s ... " "$script"
    
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

Please provide fixes for these issues, explaining each fix.
Format your response as a series of suggestions in markdown, each starting with a new heading '## Suggestion: '
followed by the explanation in a separate paragraph and then the fixed code snippet.
Output the fixed code snippet as a code block of type 'patch'.
The patch should be in the unified diff format, starting with '--- a/script' and '+++ b/script' headers,
followed by one or more hunks. Each hunk should start with '@@ -line,count +line,count @@'.
Ensure the patch can be applied to the original script without any offset.
Do not include any preceding text or paragraph before the code snippet.
The full output will only contain one heading and one paragraph for each suggestion, as well as
one code block with the patch, no other text.
Ensure each suggestion is clearly separated."

    echo ""

    # Send to Claude and get the response
    if ! claude_response=$(send_to_claude "$prompt"); then
        echo "Error: Claude API request failed."
        echo "Claude's response: $claude_response"
        exit 1
    fi
    
    # Process each suggestion and code block
    while IFS= read -r suggestion
    do
        # Extract the patch
        # shellcheck disable=SC2016
        patch=$(echo "$suggestion" | sed 's/¬/\n/g' | sed -n '/```patch/,/```/p' | sed '1d;$d')
        
        # Create temporary files
        temp_original=$(mktemp)
        temp_patched=$(mktemp)
        temp_patch=$(mktemp)
        
        # Write contents to temporary files
        printf '%s\n' "$script_content" > "$temp_original"
        printf '%s\n' "$patch" > "$temp_patch"
        
        # Attempt to apply the patch
        if patch -u "$temp_original" "$temp_patch" -o "$temp_patched" 2>/dev/null; then
            # Generate the diff
            diff_output=$(diff -u "$temp_original" "$temp_patched" | sed '1,2d')
            
            # Prepare the markdown output
            # shellcheck disable=SC2016
            markdown_output=$(cat <<EOF
$(echo "$suggestion" | sed 's/¬/\n/g' | sed '/```patch/,/```/d')

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
                        cp "$temp_patched" "$script"
                        echo "Fix applied to $script"
                        # Update script_content for the next iteration
                        script_content=$(cat "$temp_patched")
                        break
                        ;;
                    [Nn]* ) 
                        echo "Fix not applied."
                        break
                        ;;
                    * ) echo "Please answer y or n.";;
                esac
            done
        else
            echo "Error: Failed to apply patch. Attempting manual application..."
            
            # Attempt manual patch application
            manual_patch=$(echo "$patch" | sed -n '/^@@ /,$p')
            if echo "$manual_patch" | patch -u "$temp_original" -o "$temp_patched" 2>/dev/null; then
                diff_output=$(diff -u "$temp_original" "$temp_patched" | sed '1,2d')
                
                # shellcheck disable=SC2016
                markdown_output=$(cat <<EOF
$(echo "$suggestion" | sed 's/¬/\n/g' | sed '/```patch/,/```/d')

## Diff for this suggestion (manually applied)

\`\`\`diff
$diff_output
\`\`\`
EOF
)

                echo "$markdown_output" | glow -
                
                while true; do
                    printf "Do you want to apply this manually constructed fix? (y/n): "
                    read -r apply_fix < /dev/tty
                    case $apply_fix in
                        [Yy]* ) 
                            cp "$temp_patched" "$script"
                            echo "Manual fix applied to $script"
                            script_content=$(cat "$temp_patched")
                            break
                            ;;
                        [Nn]* ) 
                            echo "Manual fix not applied."
                            break
                            ;;
                        * ) echo "Please answer y or n.";;
                    esac
                done
            else
                echo "Error: Failed to apply patch manually. Skipping this suggestion."
            fi
        fi
        
        # Clean up temporary files
        rm "$temp_original" "$temp_patched" "$temp_patch"
        
        echo
    done <<EOF
$(echo "$claude_response" | awk '/^## Suggestion:/,/```$/' | sed -e '1h;1!H;$!d;x' -e 's/\n/¬/g' | sed 's/¬## Suggestion:/\n## Suggestion:/g')
EOF

    echo "All suggestions for $script processed."
    echo
done

echo "All scripts processed."
