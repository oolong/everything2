#!/usr/bin/env python
#
# An example CGI script to use hgweb, edit as necessary

# adjust python path if not a system-wide install:
#import sys
#sys.path.insert(0, "/path/to/python/lib")

# enable importing on demand to reduce startup time
from mercurial import demandimport; demandimport.enable()

# send python tracebacks to the browser if an error occurs:
import cgitb
cgitb.enable()

# If you'd like to serve pages with UTF-8 instead of your default
# locale charset, you can do so by uncommenting the following lines.
# Note that this will cause your .hgrc files to be interpreted in
# UTF-8 and all your repo files to be displayed using UTF-8.
#
import os
os.environ["HGENCODING"] = "UTF-8"

from mercurial.hgweb.hgweb_mod import hgweb
from mercurial.hgweb.request import wsgiapplication
import mercurial.hgweb.wsgicgi as wsgicgi

def make_web_app():
    return hgweb("/usr/local/everything/lib", "Everything Engine (ecore) - Development Version")

wsgicgi.launch(wsgiapplication(make_web_app))
