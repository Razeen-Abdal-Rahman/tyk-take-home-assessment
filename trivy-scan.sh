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
            .PkgName,
            .Severity,
            .InstalledVersion,
            (.FixedVersion // "N/A"),
            (.Description // "No description"),
            .VulnerabilityID
        ] | @tsv
    ' "$json_file")
    while IFS=$'\t' read -r pkg severity version fixed desc cve; do
        description=$(echo "$desc" | sed 's/"/""/g' | sed 's/,/\\,/g')
        fix=$(echo "$fixed" | sed 's/,/\t/g')
        entry="${pkg},${severity},${version},${fix},\"${description}\",${cve}"

        if [[ -v CONSOLIDATE[$cve] ]]; then
            current="${CONSOLIDATE[$cve]}"
            base="${current%%,*}"
            sources="${current#*,}"
            if [[ "$sources" != *"|$image|"* ]]; then
                CONSOLIDATE["$cve"]="${base},${sources}|$image|"
            fi
        else
            CONSOLIDATE["$cve"]="${entry},|$image|"
        fi
    done <<< "$results"
done

echo "Package Name,Severity,Version,Fixed in version,Description,CVE ID,Source(image name)" > "$OUTPUT_CSV"

for src in "${CONSOLIDATE[@]}"; do
    echo "$src" >> "$OUTPUT_CSV"
done

echo "Report complete - $OUTPUT_CSV"