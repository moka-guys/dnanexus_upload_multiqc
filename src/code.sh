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

# Create a variable containing the SSH command arguments required to determine if the file exists.
# These arguments include the options to connect to the server and the bash 'test' command, with the
# expected multiqc report file path passed to the -e flag for testing.
file_exists_test="$ssh_opts mokaguys@genomics.viapath.co.uk test -e /var/www/html/mokaguys/multiqc/reports/${multiqc_html_name}"

# Test if the file exists on the Viapath Genomics server using ssh and ${file_exist_test} arguments.
if ssh ${file_exists_test}; then
    echo "File exists."
# If the file does not exist
else
    # Upload the multiqc html to the multiqc reports directory
    rsync -avhz -e "ssh $ssh_opts" ${multiqc_html_path} mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/reports/${multiqc_html_name}
    # Call a python script to create a new index.html from html file list. This script outputs the file
    # 'new_index.html' to the current working directory.
    python update_index.py ${out_dir}/old_index.html ${multiqc_html_path}
    mv new_index.html ${out_dir}
    # Upload new index.html to server
    rsync -avhz -e "ssh $ssh_opts" ${out_dir}/new_index.html mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/index.html
fi

# Upload outputs to DNAnexus. This will always upload 'old_index.html'. If the multiqc report did
# not exist, it will also upload 'new_index.html'.
dx-upload-all-outputs
