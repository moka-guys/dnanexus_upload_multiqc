#!/usr/bin/env python
"""update_index.py

Update Multiqc index file from the Viapath Genomics Server with link to new multiqc report.

Example:
    $ python update_index.py old_index.html report-multiqc.html
Output:
    new_index.html
"""

import os
import sys
from bs4 import BeautifulSoup as Soup

# Script arguments are loaded to the sys.argv list. The expected first item is the index html file
# and the second is the multqc html
index_html = sys.argv[1]
# Remove directory prefix from multiqc html input argument
# E.g. /usr/bin/multiqc.html --> multiqc.html
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
# Note: The div 'class' attribute defines how Bootstrap3 will render the page. 
# Example HTML:
# <div class="well">
#   <h1>REPORT</h1>
#   <ul><a href="./reports/REPORT-multiqc.html">MultiQC report</a></ul>
# </div>
div_tag['class'] = "well"
h1_tag.string=multiqc_html.rstrip('-multiqc.html')
a_tag.string="MultiQC report"

# Set HTML tag nesting heirarchy
ul_tag.append(a_tag)
div_tag.append(h1_tag)
div_tag.append(ul_tag)

# Insert the HTML tags into the index file, nested within the <body> tag.
# As soup.body is a list of HTML tags nested within the HTML body. The first argument of the
# soup.body.insert() method dictates where new tags should be inserted in this list. To ensure the
# new multiqc report link appears at the top of the HTML, we insert our <br>, <div> and <br> tags in
# the 1st, 2nd, and 3rd position within the body tag.
soup.body.insert(1, br_tag)
soup.body.insert(2, div_tag)
soup.body.insert(3, br_tag2)

# Write the new index file
with open('new_index.html', 'w') as file:
	file.write(str(soup))
