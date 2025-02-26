#!/usr/bin/env python3

import os
import sys
from typing import Iterable, Literal, Optional
import string
import json
import pathlib
import shlex


class PathValue:
    def __init__(self, items: list[str] | str, pathsep: str = os.pathsep):
        self.__items: list[str] = (
            items if isinstance(items, list) else items.split(pathsep)
        )
        self.__pathsep = pathsep

    @property
    def lst(self) -> list[str]:
        return self.__items

    @property
    def str(self) -> str:
        return os.pathsep.join(self.__items)

    def __lst__(self):
        return self.__items

    def __str__(self):
        return self.str


class PathUtil:

    __sys_path: list[str] = [
        "/usr/local/sbin",
        "/usr/local/bin",
        "/usr/sbin",
        "/usr/bin",
        "/sbin",
        "/bin",
        "/snap/bin",
    ]

    def __init__(
        self,
        path: Optional[str | Iterable[str]] = None,
        pathsep: str = os.pathsep,
        **kwargs,
    ):

        self.__pathsep = pathsep
        self.__change_log: list[tuple] = (
            [] if not kwargs.get("change_log") else kwargs["log"]
        )

        if not path:
            self.__path = PathValue(os.environ["PATH"], pathsep)
        elif isinstance(path, (str, list)):
            self.__path = PathValue(path, pathsep)
        else:
            raise ValueError("Invalid path value")

        self.__change_log.append(("init", self.__path))

    def __register_change(self, change_type: str, path: str | list[str]) -> None:
        p = PathValue(path, self.__pathsep)
        self.__path = p
        self.__change_log.insert(0, (change_type, p))

    @staticmethod
    def _split_path(value: str, pathsep: str = os.pathsep) -> list[str]:
        return value.split(pathsep)

    @property
    def path(self) -> PathValue:
        return self.__path

    @property
    def string(self) -> str:
        return self.__path.str

    @property
    def lst(self) -> list[str]:
        return self.__path.lst

    def __iter__(self):
        return iter(self.__path.lst)

    def __len__(self):
        return len(self.__path.lst)

    def __str__(self):
        return self.__path.str

    def __lst__(self):
        return self.__path.lst

    def find_duplicates(self) -> list[str]:
        fresh: set[str] = set()
        duplicates = []
        for item in self:
            if item in fresh:
                if item not in duplicates:
                    duplicates.append(item)
            else:
                fresh.add(item)
        return duplicates

    def __remove_duplicates(self) -> list[str]:
        fresh: list[str] = []
        for item in self:
            if item not in fresh:
                fresh.append(item)
        return fresh

    def remove_duplicates(self) -> None:
        fresh = self.__remove_duplicates()
        self.__register_change("remove_duplicates", fresh)

    def __find_invalid(self) -> list[str]:
        invalid: set[str] = set()
        for item in self:
            if not os.path.isdir(item):
                invalid.add(item)
        return list(invalid)

    def remove_invalid(self) -> None:
        invalid_items = self.__find_invalid()
        new_path = [item for item in self if item not in invalid_items]
        self.__register_change("remove_invalid", new_path)

    def ensure_sys_path_order(self) -> None:
        new_path = [p for p in self if p not in self.__sys_path]
        other_sys_paths = [p for p in new_path if p.startswith("/usr")]
        new_path = [p for p in new_path if p not in other_sys_paths]
        new_path.extend(other_sys_paths)
        new_path.extend(self.__sys_path)
        self.__register_change("ensure_sys_path_order", new_path)

    def revert_change(self, steps: int = 1) -> None:
        if steps > len(self.__change_log):
            raise ValueError("Invalid steps")
        for _ in range(steps):
            self.__change_log.pop()
        self.__path = self.__change_log[-1][1]

    def remove_path(self, path: str) -> None:
        new_path = [p for p in self if p != path]
        self.__register_change(f"remove_path({path})", new_path)

    def add_path(
        self, path: str, meth: Literal["prepend", "append"] = "prepend"
    ) -> None:
        new_path = self.lst
        if meth == "prepend":
            new_path.append(path)
        elif meth == "append":
            new_path.append(path)
        else:
            raise ValueError(f"Invalid method: {meth}. Use 'prepend' or 'append'")
        self.__register_change(f"add_path({path})", new_path)


    def to_json(self, path: Optional[str] = None) -> str | None:
        json_str = json.dumps(self.lst, indent=2)
        if not path:
            return json_str
        with open(path, "w") as f:
            f.write(json_str)
    
    def to_shellscript(self, path: Optional[str] = None) -> str | None:
        script = f"export PATH={shlex.quote(self.string)}"
        if not path:
            return script
        with open(path, "w") as f:
            f.write(script)


import argparse

parser = argparse.ArgumentParser(description="Path manipulation tool")
parser.add_argument(
    "--path",
    type=str,
    help="Path to manipulate",
    default=os.environ["PATH"],
    nargs="?",
)

# output 
parser.add_argument(
    "--output",
    type=str,
    help="Output file",
    default=None,
)
# json flag
parser.add_argument(
    "--json",
    action="store_true",
    help="Output as JSON",
)

if __name__ == "__main__":
        
    args = parser.parse_args()

    p = PathUtil(args.path)
    p.remove_duplicates()
    p.remove_invalid()
    p.ensure_sys_path_order()
    if args.json:
        if args.output:
            p.to_json(args.output)
        else:
            print(p.to_json())
    elif not args.output:
        print(p.to_shellscript())
    else:
        p.to_shellscript(args.output)

    sys.exit(0)
    
