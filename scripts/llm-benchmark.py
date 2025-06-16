#!/usr/bin/env python3
# -----------------------------------------------------------------------------
# This script generates a CSV file showing the token/second for generating
# a Snake Game (or any user-defined prompt) in Python, TypeScript, and Java.
# It was created to test the effects of speculative decoding and various
# draft settings on performance. Writing code with a low temperature seems to
# provide fairly consistent logic.
#
# Usage example:
#   python3 llm-benchmark.py --url http://localhost:8080 \
#       --models modelA modelB \
#       --prompt "write snake game in {language}" \
#       --output results.csv
#
# If you omit `--models`, this script will:
#   1) Make a GET request to "<url>/v1/models"
#   2) Extract all "id" fields from .data[*]
#   3) Benchmark each of those models automatically
#
# The prompt template must include "{language}". Models starting with "Qwen3"
# will automatically have " /no_think" appended.
# -----------------------------------------------------------------------------

import sys
import time
import json
import csv
import argparse
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation

import requests

DEFAULT_OUTPUT_FILENAME = "benchmark_results.csv"
DEFAULT_SERVER_URL = "http://localhost:8500"
LANGUAGES = ["python", "typescript", "java"]
COMMON_HEADERS = {"Content-Type": "application/json"}
TIMINGS_FIELD = ("timings", "predicted_per_second")
SLEEP_AFTER_PRELOAD = 3
SLEEP_AFTER_REQUEST = 3
SLEEP_AFTER_UNLOAD = 3
DEFAULT_PROMPT_TEMPLATE = "write a calculator class in {language}, including unittests. i want only the code and no extra explanation. consider edge cases and add comments to each method."


def round_tps_value(value_input):
    """
    Rounds a token/second value to two decimal places, similar to printf "%.2f".
    Input can be a number or a string representing a number.
    Returns a string representation of the rounded number, or None if input is invalid.
    """
    try:
        val = Decimal(str(value_input))
        rounded_val = val.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        return f"{rounded_val}"
    except InvalidOperation:
        return None


def fetch_models_from_url(base_url):
    """
    Fetches model IDs from the given base_url/v1/models endpoint.
    Exits with an error code if fetching or parsing fails.
    """
    models_url = f"{base_url}/v1/models"
    print(
        f"No models provided → fetching all model IDs from {models_url}",
        file=sys.stderr,
    )

    try:
        response = requests.get(models_url, headers=COMMON_HEADERS)
        response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"Error fetching models from {models_url}: {err}", file=sys.stderr)
        sys.exit(1)

    try:
        data = response.json()
        items = data.get("data", [])
        fetched = [
            item["id"] for item in items if isinstance(item, dict) and item.get("id")
        ]
    except (json.JSONDecodeError, KeyError):
        print(f"Error: Unexpected JSON structure from {models_url}", file=sys.stderr)
        sys.exit(1)

    if not fetched:
        print(f"Error: No models found at {models_url}", file=sys.stderr)
        sys.exit(1)

    print(f"Found models: {', '.join(fetched)}", file=sys.stderr)
    return fetched


def build_prompt_content(language, model_id, prompt_template):
    """
    Builds the prompt content by substituting {language} into prompt_template.
    If model_id starts with 'Qwen3', appends ' /no_think'.
    """
    try:
        prompt = prompt_template.format(language=language)
    except KeyError:
        # If template is invalid (missing {language}), fallback to default
        prompt = DEFAULT_PROMPT_TEMPLATE.format(language=language)

    if model_id.startswith("Qwen3"):
        prompt += " /no_think"
    return prompt


def preload_model(model_id, url):
    """
    Sends a minimal request to preload the model. Sleeps for SLEEP_AFTER_PRELOAD seconds
    after a successful preload. Exits on failure.
    """
    try:
        response = requests.get(f"{url}/{model_id}", headers=COMMON_HEADERS)
        if response.status_code not in (200, 404):
            response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"Error preloading model {model_id}: {err}", file=sys.stderr)
        sys.exit(1)

    time.sleep(SLEEP_AFTER_PRELOAD)


def benchmark_language(model_id, language, completions_url, prompt_template):
    """
    Benchmarks a single language for a given model_id using the prompt_template.
    Returns the rounded TPS string (e.g., '123.45 tps'). Exits on failure.
    """
    prompt_text = build_prompt_content(language, model_id, prompt_template)
    payload = {
        "model": model_id,
        "messages": [{"role": "user", "content": prompt_text}],
    }

    try:
        response = requests.post(completions_url, json=payload, headers=COMMON_HEADERS)
        time.sleep(SLEEP_AFTER_REQUEST)
        response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(
            f"Error during benchmark for model {model_id}, lang {language}: {err}",
            file=sys.stderr,
        )
        return "0.0 tps"

    try:
        data = response.json()
        tps_raw = data
        for key in TIMINGS_FIELD:
            tps_raw = tps_raw.get(key, None)
            if tps_raw is None:
                break
    except json.JSONDecodeError:
        print(
            f"Error: Could not decode JSON for model {model_id}, lang {language}.",
            file=sys.stderr,
        )
        return "0.0 tps"

    if tps_raw is None:
        print(
            f"Error: 'timings.predicted_per_second' missing for model {model_id}, lang {language}.",
            file=sys.stderr,
        )
        return "0.0 tps"

    tps_str = round_tps_value(tps_raw)
    if tps_str is None:
        print(
            f"Error: Invalid TPS value '{tps_raw}' for {model_id}, lang {language}.",
            file=sys.stderr,
        )
        return "0.0 tps"

    return f"{tps_str} tps"


def unload_model(url):
    try:
        response = requests.get(url, headers=COMMON_HEADERS)
        response.raise_for_status()
    except requests.exceptions.RequestException as err:
        print(f"Error unloading model: {err}", file=sys.stderr)

    time.sleep(SLEEP_AFTER_UNLOAD)


def write_results_to_csv(results, header, filename):
    """
    Writes the benchmarking results to a CSV file. Exits on I/O error.
    """
    try:
        with open(filename, "w", newline="", encoding="utf-8") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(header)
            writer.writerows(results)
    except IOError as err:
        print(f"Error writing CSV file {filename}: {err}", file=sys.stderr)
        sys.exit(1)


def run_benchmark():
    parser = argparse.ArgumentParser(
        description=(
            "Generates a CSV file showing the token/second for generating a Snake Game "
            "or any user-defined prompt in Python, TypeScript, and Java. This script "
            "tests the effects of speculative decoding and various draft settings on performance."
        ),
        epilog=(
            "Original shell script: "
            "https://github.com/mostlygeek/llama-swap/tree/main/examples/benchmark-snakegame"
        ),
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "--url",
        default=DEFAULT_SERVER_URL,
        help="The base URL of the API (e.g., http://localhost:8080).",
    )
    parser.add_argument(
        "--models",
        nargs="*",
        metavar="model",
        help="Optional list of model IDs to benchmark. If omitted, fetches from <url>/v1/models.",
    )
    parser.add_argument(
        "--prompt",
        default=DEFAULT_PROMPT_TEMPLATE,
        help=(
            "Prompt template to send. Must include '{language}' as a placeholder. "
            f'Default: "{DEFAULT_PROMPT_TEMPLATE}"'
        ),
    )
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT_FILENAME,
        help=f"CSV filename to save results to (default: {DEFAULT_OUTPUT_FILENAME}).",
    )

    args = parser.parse_args()
    base_url = args.url.rstrip("/")
    output_filename = args.output
    prompt_template = args.prompt

    models = args.models if args.models else fetch_models_from_url(base_url)
    models.sort()
    completions_endpoint = f"{base_url}/v1/chat/completions"
    load_endpoint = f"{base_url}/upstream"
    unload_endpoint = f"{base_url}/unload"
    csv_header = ["model"] + LANGUAGES
    all_results = []

    print(f"Used Prompt:\n{prompt_template}\n")

    for model_id in models:
        print(f"Benchmarking model: {model_id}", file=sys.stderr)

        # Preload model
        print(f"  Preloading {model_id}...", file=sys.stderr)
        preload_model(model_id, load_endpoint)

        row = [model_id]
        for lang in LANGUAGES:
            print(f"  Benchmarking {lang} for {model_id}...", file=sys.stderr)
            tps_result = benchmark_language(
                model_id, lang, completions_endpoint, prompt_template
            )
            row.append(tps_result)

        all_results.append(row)
        print("Unloading Model...", file=sys.stderr)
        unload_model(unload_endpoint)

    # Write to CSV
    write_results_to_csv(all_results, csv_header, output_filename)
    print(f"\nBenchmark finished. Results saved to {output_filename}", file=sys.stderr)


if __name__ == "__main__":
    run_benchmark()
