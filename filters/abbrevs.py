#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Replace all abbreviations defined in file 'dbase' (assumed to be in default '.pandoc' direc), and in document metadata.
Abbreviations in PDmarkdown are marked by a preceding '+'.
In document metadata -> '+abbrev: expansion'.
If an abbreviation cannot be found, it will be marked in output with double exclamation marks '!!'
"""
import sys
import json
import os
import re
from pandocfilters import *

regex = re.compile('^\+|^\(\+|^\[\+|^\{\+')#create pattern to detect abbreviations, starting with a + but may be preceded by some sort of bracket/parenthesis etc

def abbreplace(key, value, format, meta):

    # add abbreviations from file metadata
    for k, v in meta.items():#get keys, values for all metadata
        if k.startswith('+'):# does the key start with a plus sign?
            abbrevlist[str(k.strip('+'))] = stringify(v['c']) # add key and value to the abbrev dictionary

    if key == 'Str' and re.match(regex, value):# is the string an abbrev? (starts with a plus/bracket? see line 20)
        bare = value.strip('.,;:(()[]{}’')# get the bare abbrev string by stripping potential punctutation
        rp = value.lstrip('.,;: ()[]{}’')# strip punct chars from left
        rp2 = rp.lstrip(bare)# strip abbrev from left, leaving only punct chars on right of abbreviations
        lp = value.rstrip('.,;: ()[]{}’')
        lp2 = lp.rstrip(bare)# same as previous two lines but on LHS

        if bare.startswith('++'):
            return RawInline('latex', lp2 + '\\acsp{' + bare.strip('+') + '}' + rp2)# send back the 'value' of the abbrev 'key', adding stored punctuation
        else:
            return RawInline('latex', lp2 + '\\acs{' + bare.strip('+') + '}' + rp2)# send back the 'value' of the abbrev 'key', adding stored punctuation

if __name__ == "__main__":
    toJSONFilter(abbreplace)