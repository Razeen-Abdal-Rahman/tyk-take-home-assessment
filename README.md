# 🔍 Vulnerability Scanner

This repository contains a simple shell script to scan Docker images from the using [Trivy](https://github.com/aquasecurity/trivy) and output it as a single deduplicated CSV report.

---

## 🚨 Prerequisites

Make sure you have the following installed on your system:

- [Trivy](https://aquasecurity.github.io/trivy/) (`brew install trivy` or [see docs](https://trivy.dev/latest/getting-started/installation/))
- `jq`
- `bash`

---

## 🚀 Features

- Scans any number of public images
- Automatically consolidates and deduplicates vulnerabilities across images
- Outputs a CSV with all required fields
- Handles missing fields gracefully (e.g., missing fixed versions or descriptions)
- Temporary files are stored in a secure temp directory and cleaned up automatically once the script is complete

---

## 📂 Files

- `trivy-scan.sh`: The main script to run  
- `trivy_scan_report.csv`: Sample output report generated from Tyk images  
- `README.md`: You’re reading it 🙂

---

## 🛠️ Usage

1. Clone this repository:
   ```git clone https://github.com/Razeen-Abdal-Rahman/tyk-take-home-assessment.git```
   ```cd tyk-vuln-scanner```
2. Make the script executeable:
   ```chmod +x trivy-scan.sh```
3. Run the scanner with the names of the images:
   ```./trivy-scan.sh tykio/midsommar tykio/tyk-dashboard``` 
4. The output file will be overwritten your report will be saved as ```trivy_scan_report.csv```
