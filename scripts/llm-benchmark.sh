#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# This script generates a CSV file showing the token/second for generating a Snake Game in python, typescript and swift                                                                      
# It was created to test the effects of speculative decoding and the various draft settings on performance.                                                                                  
#                                                                                                                                                                                            
# Writing code with a low temperature seems to provide fairly consistent logic.       
#
# Usage:
#   ./run-benchmark.sh <url> [<model1> <model2> …]
#
# If only <url> is provided, this script will:
#   1) curl "$url"
#   2) extract all "id" fields from .data[*] (using jq)
#   3) benchmark each of those models automatically
#
# If you explicitly pass models after the <url>, it will only benchmark those.
#
# Requires:
#   - curl
#   - jq
#
# Script based on https://github.com/mostlygeek/llama-swap/tree/main/examples/benchmark-snakegame
# -----------------------------------------------------------------------------
                                                                                      
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <url> [model1 model2 …]"
    exit 1
fi

url=$1
shift

if [ "$#" -eq 0 ]; then
    echo "No models provided on the command line → fetching all model IDs from $url"

    # Pull the JSON and extract every .data[].id
    # (Assumes the endpoint returns something like: { "data": [ { "id": "…", … }, { "id": "…", … }, … ] } )
    models=( $(curl -s --fail "$url/v1/models" \
                   | jq -r '.data[]?.id') )

    if [ "${#models[@]}" -eq 0 ]; then
        echo "Error: No models found at $url (or jq failed)."
        exit 1
    fi
else
    models=( "$@" )
fi

# Print CSV header
echo "model,python,typescript,swift"

# Loop over each model and benchmark it in python, typescript, swift
for model in "${models[@]}"; do
    echo -n "$model,"

    # Preload
    curl -s --fail \
        --url "$url/v1/chat/completions" \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "'"$model"'",
            "messages": [ { "role": "user", "content": "hi" } ]
        }'

    for lang in "python" "typescript" "swift"; do
        tps=$(curl -s --fail \
            --url "$url/v1/chat/completions" \
            -H 'Content-Type: application/json' \
            -d '{
                    "messages": [
                      { "role": "system", "content": "you only write code." },
                      { "role": "user", "content": "write snake game in '"$lang"'" }
                    ],
                    "top_k": 1,
                    "timings_per_token": true,
                    "model": "'"$model"'"
                }' \
            | jq -r '.timings.predicted_per_second')

        # If curl/jq failed for this combination, bail
        if [[ $? -ne 0 ]] || [[ -z "$tps" ]] || [[ "$tps" == "null" ]]; then
            echo "error"
            exit 1
        fi

        # Round tps to two decimal places
        tps_rounded=$(echo "$tps" | awk '{printf "%.2f", $1}')

         if [[ "$lang" != "swift" ]]; then
            printf "%s tps," "$tps_rounded"
        else
            printf "%s tps\n" "$tps_rounded"
        fi
    done
done