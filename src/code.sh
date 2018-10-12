#!/bin/bash

# -e = exit on error; -x = output each line that is executed to log; -o pipefail = throw an error if there's an error in pipeline
set -e -x -o pipefail

# Download input data
dx-download-all-inputs

# Create output directory
out_dir="output/QC/multiqc/upload_multiqc/"
mkdir -p ${out_dir}

# Download old index.html for archiving
scp mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/index.html ${out_dir}

# Copy HTML file to viapath server
scp ${multiqc_html_path} mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/reports

# Get list of multiqc html files from server
ssh multiqc@genomics.viapath.co.uk ls -rt /var/www/html/mokaguys/multiqc/reports/*.html > multiqc_reports.txt

# Call python script to create a new index.html from html file list
python update_index.py

# Upload new index.html to server
scp index.html mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/

# Upload outputs to DNAnexus
dx-upload-all-outputs
