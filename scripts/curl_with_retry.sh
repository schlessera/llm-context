#!/bin/sh

# Helper function to perform curl with retries
curl_with_retry() {
    url="$1"
    output_file="$2"
    max_retries="${3:-10}"
    retry_delay="${4:-1}"
    failure_msg="${5:-❌}"
    success_msg="${6:-✅}"
    timeout="${7:-5}"

    i=1
    while [ $i -le "$max_retries" ]; do
        error=$(curl -s -f -m "$timeout" -o "$output_file" "$url" 2>&1)
        exit_code=$?

        if [ "$exit_code" -eq 0 ]; then
            printf "%s" "$success_msg"
            return 0
        fi

        printf "%s" "$failure_msg"

        # Check if the error is worth retrying (e.g., connection issues, server errors)
        if [ "$exit_code" -eq 22 ] || [ "$exit_code" -eq 28 ] || [ "$exit_code" -eq 56 ]; then
            sleep "$retry_delay"
        else
            break
        fi
        i=$((i + 1))
    done

    printf " (%s)" "$error"
    
    return $exit_code
}
