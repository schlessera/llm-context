#!/bin/sh

# Function to run shellcheck on files
run_shellcheck() {
    output_format="$1"
    shift

    if [ $# -eq 0 ]; then
        echo "Checking all .sh files in all subfolders"
        find . -type f -name "*.sh" -print0 | xargs -0 -I {} shellcheck ${output_format:+-f "$output_format"} {}
    else
        echo "Checking specified files"
        shellcheck ${output_format:+-f "$output_format"} "$@"
    fi
}

# Parse command line arguments
output_format=""
while getopts "f:" opt; do
    case ${opt} in
        f )
            output_format=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Run shellcheck with the specified output format (if any)
if run_shellcheck "$output_format" "$@"; then
    echo "All scripts passed shellcheck"
    exit 0
else
    echo "Some scripts failed shellcheck"
    exit 1
fi
