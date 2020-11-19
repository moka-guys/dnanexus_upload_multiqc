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

# Test if the file exists on the Viapath Genomics server using ssh and ${file_exist_test} arguments. Exit with error code 1 if True.
if ssh ${file_exists_test}; then
    echo "ERROR: ${multiqc_html_name} exists at /var/www/html/mokaguys/multiqc/reports/." 1>&2
    exit 1
fi

# Upload the multiqc html to the multiqc reports directory
rsync -avhz -e "ssh $ssh_opts" ${multiqc_html_path} mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/reports/${multiqc_html_name}
# Call a python script to create a new index.html from html file list. This script outputs the file
# 'new_index.html' to the current working directory.
python update_index.py ${out_dir}/old_index.html ${multiqc_html_path}
mv new_index.html ${out_dir}
# Upload new index.html to server
rsync -avhz -e "ssh $ssh_opts" ${out_dir}/new_index.html mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/index.html

if [[ "$upload_data_files" == "true" ]]; then
    # capture the project name from the multiqc html name (project_name-multiqc.html)
    project_name=$(echo $multiqc_html_name | rev | cut -f2-3 -d "-" | rev)
    # a string which ssh's onto server and looks for a folder with the runfolder name in the location which holds multiqc data
    # this returns a string if the folder path exists
    dir_exists_test="$ssh_opts mokaguys@genomics.viapath.co.uk [ -d /var/www/html/mokaguys/multiqc/trend_analysis/multiqc_data/$project_name ] && echo dir_ exists"
    
    # If there is a folder matching project name exit with error code 1.
    if [[ $(ssh ${dir_exists_test}) == "dir exists" ]]; then
        echo "ERROR: ${project_name} data already on server at /var/www/html/mokaguys/multiqc/trend_analysis/multiqc_data" 1>&2
        exit 1
    fi
    # if doesn't already exist create folder
    create_folder="$ssh_opts mokaguys@genomics.viapath.co.uk mkdir /var/www/html/mokaguys/multiqc/trend_analysis/multiqc_data/${project_name}"
    ssh $create_folder
    # for each data file in $multiqc_data_input upload to server 
    for data_file_path in "${multiqc_data_input_path[@]}"; do
        # Upload the multiqc data files to the multiqc reports directory
        rsync -avhz -e "ssh $ssh_opts" ${data_file_path} mokaguys@genomics.viapath.co.uk:/var/www/html/mokaguys/multiqc/trend_analysis/multiqc_data/${project_name}
    done
fi

# Upload outputs to DNAnexus. This will always upload 'old_index.html'. If the multiqc report did
# not exist, it will also upload 'new_index.html'.
dx-upload-all-outputs
