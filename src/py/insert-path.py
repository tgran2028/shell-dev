#!/usr/bin/python3

"""
This script inserts a specified directory into the system PATH variable at a given index.

Usage:
    insert_path PATH INDEX [PATH]

    - PATH (positional): The directory to insert into PATH. Must reference an existing directory.
    - INDEX (positional): The index at which to insert the directory into the current PATH components.
    - PATH (positional, optional): The PATH variable to modify; if omitted, the environment variable PATH is used.

Optional Arguments:
    --diff          Show the difference between the old PATH and the new PATH using a diff command.
    -l, --list      Output the result as a list of paths (one path per line).
    -j, --json      Output the result as a JSON formatted string.

Description:
    The script performs the following steps:
      1. Parses command-line arguments.
      2. Validates that the provided directory exists.
      3. Converts the directory path to its absolute form.
      4. Splits the given PATH into individual directory components using the OS-specific separator.
      5. Removes any duplicates of the directory from the PATH.
      6. Inserts the directory at the specified index within the PATH components.
      7. Formats the updated PATH based on the chosen output format (shellscript, json, or list).
      8. If requested (--diff), displays a diff between the original and new PATH values.
      9. Otherwise, outputs the formatted new PATH.

Exit Codes:
    0: Successful execution.
    1: An error occurred during execution.

Author:
    (Your Name/Contact Information, if desired)

"""

import json
import os
import sys
import argparse
import tempfile
from os import pathsep as psep
from typing import Literal
import copy


def format_path(path: str, fmt: Literal["shellscript", "json", "list"]) -> str:
    """
    Formats a file path string based on the specified output format.

    Parameters:
        path (str): The file path to format.
        fmt (Literal["shellscript", "json", "list"]): The format to apply. Valid options are:
            - "shellscript": Returns the path with leading and trailing whitespaces removed.
            - "json": Splits the path using the platform-specific separator (psep), formats the list as a JSON string with indentation,
                      and appends a newline.
            - "list": Splits the path into segments using the platform-specific separator (psep) and joins them with newline characters,
                      trimming any extra whitespace and appending a newline.

    Returns:
        str: The formatted path string.

    Raises:
        ValueError: If the provided format is not one of the supported options.
    """
    if fmt == "shellscript":
        return path.strip()
    elif fmt == "json":
        return json.dumps(path.split(psep), indent=2).strip() + "\n"
    elif fmt == "list":
        return "\n".join(path.split(psep)).strip() + "\n"
    else:
        raise ValueError(f"Invalid format {fmt}")


def parse_args() -> argparse.Namespace:
    """Parse command line arguments.

    Parses command-line arguments and returns an argparse.Namespace object.
    """
    parser = argparse.ArgumentParser(
        description="Insert path into PATH variable", prog="insert_path", add_help=True,
    )
    # required (1 dir that exists)
    parser.add_argument(
        "dir", help="Directory to insert into PATH", metavar="DIR", type=str
    )
    # required
    parser.add_argument(
        "i",
        help="Index position to insert directory into $PATH paths",
        type=int,
        metavar="INDEX",
        # nargs=1
    )
    # optional (default is PATH)
    parser.add_argument(
        "PATH",
        help="PATH variable to insert directory into",
        type=str,
        nargs="?",
        default=os.environ.get("PATH", ""),
        metavar="PATH",
        const=os.environ.get("PATH", ""),
        # required=False,
    )
    parser.add_argument(
        "--diff",
        help="Show the difference between the old PATH and the new PATH",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "-l",
        "--list",
        help="Return result as list of paths (not joined by psep)",
        action="store_true",
        default=False,
    )
    parser.add_argument(
        "-j",
        "--json",
        help="Return result as json",
        action="store_true",
        default=False,
    )
    return parser.parse_args()


def test_insert(cnt: int, index: int) -> bool:
    try :
        rng = ['foo' for _ in range(cnt)]
        rng.insert(index, 'bar')
        return True
    except TypeError as e:
        return False
    

absp = os.path.abspath
isdir = os.path.isdir


def main() -> Literal[0, 1]:
    """
    Main function to update the environment PATH by inserting a user-specified directory at a given index.

    Process:
        1. Parse command-line arguments.
        2. Validate that a directory (to be inserted) is provided; otherwise, print an error and exit.
        3. Normalize and resolve the absolute path of the directory.
        4. Create a list of existing paths from the current PATH environment variable, excluding any instance of the directory.
        5. Ensure the provided index is within the valid range of the paths list.
        6. Insert the directory at the provided index.
        7. Format both the original and updated PATH values according to the specified output format (shellscript, json, or list).
        8. If a diff flag is set,:
             - Write the original and updated PATH data into temporary files.
             - Execute a system diff command to compare these files.
           Otherwise, print the new PATH content directly.
        9. Return 0 on successful execution, or, in case of any exception, print the error message and return 1.
    """
    try:
        args = parse_args()
        if not args.dir:
            print("Must provide a directory to insert into PATH")
            sys.exit(1)

        # dir to insert into PATH
        _dir = absp(args.dir)

        path_original = copy.deepcopy(args.PATH)
        # list of paths in PATH. Remove dir to insert if it exists, so can be reinserted at index i
        paths = [absp(p) for p in args.PATH.split(psep) if absp(p) != _dir and isdir(p)]
        # assert args.i <= len(paths) and args.i >= 0, f"Index {args.i} out of range"
        try:
            rng = ['foo' for _ in range(args.i)]
            rng.insert(args.i, 'bar')
        except TypeError as e:
            raise ValueError(f"Index {args.i} out of range. There are {len(paths)} paths in PATH") from e

        paths.insert(args.i, _dir)
        new_path = psep.join(paths).strip(psep)

        if not args.json and not args.list:
            fmt = "shellscript"
            ext = ".sh"
        elif args.json:
            fmt = "json"
            ext = ".json"
        else:
            fmt = "list"
            ext = ".txt"

        old_path_content = format_path(path_original, fmt)
        new_path_content = format_path(new_path, fmt)

        if args.diff:
            # create dir, write old and new PATH to file, and run diff
            with tempfile.TemporaryDirectory() as tmpdir:
                old_path = os.path.join(tmpdir, f"old_path{ext}")
                new_path_file = os.path.join(tmpdir, f"new_path{ext}")
                with open(old_path, "w") as f:
                    f.write(old_path_content)
                with open(new_path_file, "w") as f:
                    f.write(new_path_content)
                os.system(f"diff {old_path} {new_path_file}")
        else:
            print(
                new_path_content,
                end="" if fmt == "shellscript" else "\n",
                flush=True,
                file=sys.stdout,
            )
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
