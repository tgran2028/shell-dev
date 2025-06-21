#!/usr/bin/python3

from xdg.DesktopEntry import DesktopEntry
import sys
import json


def desktop_entry_to_dict(path: str):
    e = DesktopEntry(path)
    print(e)
    data = e.__dict__
    if not 'content' in data:
        raise ValueError("Invalid desktop entry file")
    e.__dict__['content']['Desktop Entry']


def main():
    if len(sys.argv) < 2:
        print("Usage: {r} <desktop_entry_file>".format(sys.argv[0]))
        sys.exit(1)

    e = desktop_entry_to_dict(sys.argv[1])
    sys.stdout.write(json.dumps(e, indent=2))
    sys.exit(0)
