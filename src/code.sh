#!/bin/bash

# -e = exit on error; -x = output each line that is executed to log; -o pipefail = throw an error if there's an error in pipeline
set -e -x -o pipefail

# Download input data
dx-download-all-inputs

# Create output directory
out_dir=/home/dnanexus/out/upload_multiqc/QC/multiqc/
mkdir -p ${out_dir}

# Set correct permissions for DNAnexus worker @/.ssh key directory
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 664 ~/.ssh/id_rsa.pub

# Create variable containing options for connecting to genomics server via ssh.
# -q suppresses warnings, -i indicates the SSH private key to use, -l presents username (required by rsync)
# StrictHostKeyChecking=no; stops failed connections based on new unrecognised hosts
# UserKnwonHostsFile=/dev/null; uses a blank file for skip check of known host keys
ssh_opts='-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/dnanexus/.ssh/id_rsa -l mokaguys'

# Download old index.html for archiving
# Rsync options: -a archive mode for recursive copy, -v verbose outputs, -h human-readable numbers,
#   -z use compression in data transfer, -e SSH command with options
rsync -avhz -e "ssh $ssh_opts" mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/index.html ${out_dir}/old_index.html

# Copy HTML file to the server if it does not exist in the correct location
file_exists_test="$ssh_opts mokaguys@genomics.viapath.co.uk test -e /var/www/html/mokaguys/multiqc/${multiqc_html_name}"
if ssh ${file_exists_test}; then
   echo "File exists"
else
   rsync -avhz -e "ssh $ssh_opts" ${multiqc_html_path} mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/reports/${multiqc_html_name}
fi

# Call python script to create a new index.html from html file list
python update_index.py ${out_dir}/old_index.html ${multiqc_html_path} > ${out_dir}/new_index.html

# Upload new index.html to server
rsync -avhz -e "ssh $ssh_opts" ${out_dir}/new_index.html mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/index.html

# Upload outputs to DNAnexus
dx-upload-all-outputs
