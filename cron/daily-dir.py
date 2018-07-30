#!/usr/bin/env python
import datetime
import os
import sys
import syslog

syslog.openlog(facility=syslog.LOG_CRON)


class GlobalVar(object):
    DIR_PATH=None


def create_dir(d):
    if not os.path.exists(d):
        syslog.syslog('create dir %s' % d)
        os.mkdir(d)


def remove_dir(d):
    try:
        syslog.syslog('remove dir %s' % d)
        os.rmdir(d)
    except:
        pass


def dir_is_empty(d):
    if os.path.isdir(d):
        return os.listdir(d) == []
    else:
        return False


def dir_names():
    now = datetime.datetime.now()
    yesterday = now - datetime.timedelta(days=1)

    today = now.strftime('%Y%m%d')
    yesterday = yesterday.strftime('%Y%m%d')
    today = os.path.join(GlobalVar.DIR_PATH, today)
    yesterday = os.path.join(GlobalVar.DIR_PATH, yesterday)
    return today, yesterday


def main(dir_path):
    GlobalVar.DIR_PATH = dir_path
    today, yesterday = dir_names()
    create_dir(today)
    if dir_is_empty(yesterday):
        remove_dir(yesterday)


if __name__ == '__main__':
    sys.exit(main(*sys.argv[1:]))
