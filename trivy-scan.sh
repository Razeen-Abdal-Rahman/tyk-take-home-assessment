#!/bin/bash

set -euo pipefail

IMAGES=("$@")
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT
OUTPUT_CSV="trivy_scan_report.csv"

echo "images to be scanned: ${IMAGES[*]}"

scan_image() {
    local image=$1
    local file=$2
    trivy image --quiet --format json "$image" > "$file"
}

declare -A CONSOLIDATE

for image in "${IMAGES[@]}"; do
    name=$(echo "$image" | tr '/:' '_')
    json_file="$TMP_DIR/${name}.json"
    
    echo "Scanning $image..."
    scan_image "$image" "$json_file"

    results=$(jq -r --arg image "$image" '
        .Results[]? |
        select(.Vulnerabilities != null) | 
        .Vulnerabilities[]? |
        select(type == "object" and has("VulnerabilityID")) |
        [
            .VulnerabilityID,
            .PkgName,
            .Severity,
            .InstalledVersion,
            (.FixedVersion // "N/A"),
            (.Description // "No description") | gsub("[\n\r]"; " ")
        ] | @tsv
    ' "$json_file")
    while IFS=$'\t' read -r cve pkg severity version fixed desc; do
        description=$(echo "$desc" | sed 's/"/""/g' | sed 's/,/\\,/g')
        key="$cve"
        entry="${cve},${pkg},${severity},${version},${fixed},\"${description}\""

        if [[ -v CONSOLIDATE[$key] ]]; then
            if [[ "${CONSOLIDATE[$key]}" != *",$image"* ]]; then
                CONSOLIDATE["$key"]="${CONSOLIDATE[$key]} + $image"
            fi
        else
            CONSOLIDATE["$key"]="${entry},$image"
        fi
    done <<< "$results"
done

echo "CVE ID,Package Name,Severity,Version,Fixed in version,Description,Source(image name)" > "$OUTPUT_CSV"

for src in "${CONSOLIDATE[@]}"; do
    echo "$src" >> "$OUTPUT_CSV"
done

echo "Report complete - $OUTPUT_CSV"