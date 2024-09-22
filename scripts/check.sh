#!/bin/sh

# Function to run shellcheck on files
run_shellcheck() {
    if [ $# -eq 0 ]; then
        echo "Checking all .sh files in all subfolders"
        find . -type f -name "*.sh" -print0 | xargs -0 -I {} shellcheck {}
    else
        echo "Checking specified files"
        shellcheck "$@"
    fi
}

# Check the result of run_shellcheck directly
if run_shellcheck "$@"; then
    echo "All scripts passed shellcheck"
    exit 0
else
    echo "Some scripts failed shellcheck"
    exit 1
fi
