#!/usr/bin/python
import sys
import argparse
import re
import os
import requests

def print_help():
    print '%s <url_prefix> <log_names_file> <log_name_pattern>'

def make_url(prefix, url):
    return '/'.join([prefix, url])

def fetch_log(url):
    url = url.rstrip('/')
    filename = os.path.basename(url)
    print 'Downloading %s => %s' % (url, filename)
    r = requests.get(url, stream=True)
    with open(filename, 'wb') as f:
        f.write(r.raw)
        for chunk in r.iter_content(chunk_size=1024):
            if chunk:
                f.write(chunk)


def main():
    parser = argparse.ArgumentParser(description='fetch_logs')
    parser.add_argument('url_prefix')
    parser.add_argument('log_file')
    parser.add_argument('pattern')

    args = parser.parse_args()

    pattern = re.compile(args.pattern)
    with open(args.log_file) as f:
        for line in f:
            line = line.strip()
            ret = pattern.match(line)
            if ret:
                gs = ret.groups()
                if gs:
                    content = ''.join(gs)
                else:
                    content = line
                fetch_log(make_url(args.url_prefix, content))


if __name__ == '__main__':
    main()
