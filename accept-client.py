#UEDIN script provided to access UEDIN API. This is third-party code!
#Changed on 22/03/2012: extra parameter 'system', which should be set to either 'sb' (symantec baseline) or 'tb' (twb baseline). 
#Changed on 27/03/2012: use command line options
#!/usr/bin/env python
# coding=utf8

#
# Translates using the google api style interface
#

import json
import urllib
import os
from optparse import OptionParser

SRC_LANGS = ["en", "fr"]
TGT_LANGS = ["en", "fr", "de", "ja"]
SYSTEMS = ["tb", "sb"]

def main(**kwargs):
#    urls = ["http://accept:motelone@accept.statmt.org/demo/translate.php"]
#    for url in urls:
        #print url
    url = kwargs.get("url")
    source = kwargs.get("source")
    target = kwargs.get("target")
    system = kwargs.get("system")
    cache = kwargs.get("cache")
    output_fn = kwargs.get("output")
    if cache and not os.path.isfile(cache):
        raise IOError('Not a valid file: %s' % cache)
    input_text = kwargs.get("input")
    if os.path.isfile(input_text):
        print input_text
        if output_fn == "":
            output_fn = "%s.%s_%s" % (input_text, source, target)
        with open(input_text, 'rb') as f:
            if cache:
                cache_lines = {}
                for l in open(cache).readlines():
                    cache_line = l.split('\t')
                    cache_lines[cache_line[0].rstrip()] = cache_line[1]
                    #raise ValueError('File does not contain 2 tab-delimited fields: %s' % cache)
            #print cache_lines
            #sys.exit()
            with open(output_fn, 'w') as f_out:
                for i,line in enumerate(f.readlines()):
                    #if i in range(0, len(f.readlines()), 10):
                    print i
                    if line.rstrip() == "":
                        f_out.write(line)
                    else:
                        if cache and line.rstrip() in cache_lines:
                            print 'Matched!'
                            f_out.write(cache_lines[line.rstrip()])
                        else:
                            print 'Translating...'
                            params = urllib.urlencode({'v' : '1.0', 'ie' : 'UTF8', \
                                'langpair' : '%s|%s' % (source,target), 'q' : line.rstrip(), 'system': system})
                            f = urllib.urlopen(url,params)
                            response = json.loads(f.readline())
                            f_out.write(response['responseData']['translatedText'].encode('utf-8') + '\n')
    else:
        params = urllib.urlencode({'v' : '1.0', 'ie' : 'UTF8', \
            'langpair' : '%s|%s' % (source,target), 'q' : input_text, 'system': system})
        f = urllib.urlopen(url,params)
        response = json.loads(f.readline())
        print response['responseData']['translatedText'].encode('utf-8')
            
if __name__ == "__main__":

    parser = OptionParser()
    parser.add_option('-s', '--source', dest='source', action='store', default='en',
                            help='One of supported source languages: %s' % "|".join(SRC_LANGS))
    parser.add_option('-t', '--target', dest='target', action='store', default='fr',
                                help='One of supported target languages: %s' % "|".join(TGT_LANGS))
    parser.add_option('-y', '--system', dest='system', action='store', default='sb',
                                help='One of supported systems: %s' % "|".join(SYSTEMS))
    parser.add_option('-c', '--cache', dest='cache', action='store',
                                help='Optional: Tab-delimited cache file with existing translations to avoid re-translating input lines if they are found in the cache)')
    parser.add_option('-i', '--input', dest='input', action='store', 
    default="I clearly stated in my earlier post this is what the tech guy did - and I reported his exact steps .",
                    help='Input file or text to translate')
    parser.add_option('-u', '--url', dest='url', action='store', 
    default="http://accept:motelone@accept.statmt.org/demo/translate.php",
                    help='Translate API URL')
    parser.add_option('-o', '--output', dest='output', action='store',
    default="",
    help='Name of the output file, instead of infile.sl_tl')
    (options,args) = parser.parse_args()
    options_dict = options.__dict__
    main(**options_dict)
