# update_index.py
# Updates multiqc index file on viapath genomics server
# usage: python update_index.py
# created: 181012
# author: Nana Mensah

import os
from jinja2 import Template

class MultiQCReport():
    def __init__(self, fullpath):
        base = os.path.basename(fullpath).strip()
        self.path = os.path.join('.','reports', base)
        self.name = base.rstrip('-multiqc.html')

# Read html file list
with open('multiqc_reports.txt') as f:
    reports_list =  f.readlines()

# Provide report objects for template
reports = ( MultiQCReport(file) for file in reports_list)

# Read jinja2 template file
with open('template.html', 'r') as file:
    index_template = Template(file.read())

# Write index
with open('index.html', 'w') as index:
    index.write(index_template.render(reports=reports))