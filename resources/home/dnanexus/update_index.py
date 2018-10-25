#!/usr/bin/env python
"""update_index.py

Update Multiqc index file from the Viapath Genomics Server with link to new multiqc report.

Example:
    $ python update_index.py old_index.html report-multiqc.html > new_index.html
"""

import os
import sys
from bs4 import BeautifulSoup as Soup

# Parse script arguments
index_html = sys.argv[1]
multiqc_html = os.path.basename(sys.argv[2])

# Open the index file as a BeautifulSoup.Soup class. This reads the HTML tags as python objects.
with open(index_html) as index:
    soup=Soup(index.read(), features="html.parser")

# Create HTML tags
br_tag = soup.new_tag('br')
br_tag2 = soup.new_tag('br')
div_tag = soup.new_tag('div')
h1_tag = soup.new_tag('h1')
ul_tag = soup.new_tag('ul')
a_tag = soup.new_tag('a', href="./reports/{}".format(multiqc_html))

# Set HTML tag metadata
# Note: The div 'class' attribute defines how Bootstrap3 will render the page
div_tag['class'] = "well"
h1_tag.string=multiqc_html.rstrip('-multiqc.html')
a_tag.string="MultiQC report"

# Set HTML tag nesting heirarchy
ul_tag.append(a_tag)
div_tag.append(h1_tag)
div_tag.append(ul_tag)

# Insert the HTML tags into the index file, nested within the <body> tag
soup.body.insert(1, br_tag)
soup.body.insert(2, div_tag)
soup.body.insert(3, br_tag2)

# Print the new index to the stdout stream
print(soup)