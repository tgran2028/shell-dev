#!/usr/bin/python

import sys
import os
from pathlib import Path
import argparse
import typer
from typing import Optional, List, Union, Dict, Any, Annotated, Tuple, Literal
from enum import Enum, StrEnum
import json
import logging
import yaml
import toml


app = typer.Typer(
    name="pathutil",
    help="Utility to process PATH environment variable.",
    add_completion=False,
    no_args_is_help=True,
)


class Format(StrEnum):
    path = "path"
    list: str = "list"
    json = "json"
    yaml: str = "yaml"
    toml: str = "toml"


def clean_path(
    path: str | Path,
    must_exist: bool = False,
    abs_path: bool = True,
    resolve: bool = False,
) -> str | None:
    """
    Clean a path.

    Args:
        path (str | Path): Directory path to clean.
        must_exist (bool, optional): Check if the path exists. Defaults to False.
        abs_path (bool, optional): Return the absolute path. Defaults to True.
        resolve (bool, optional): Resolve the path. Defaults to False.

    Returns:
        str | None: Cleaned path.
    """
    p = Path(str(path)).expanduser()
    if resolve:
        p = p.resolve()
    if must_exist:
        if not p.exists() or not p.is_dir():
            return None
    if abs_path:
        p = p.absolute()
    return str(p)


def get_paths(path: str | Path | List[str | Path], must_exist: bool = False, abs_path: bool = True, resolve: bool = False) -> list[str]:
    """
    Get a list of paths.

    Args:
        path (str | Path | List[str | Path]): Path or list of paths.
        must_exist (bool, optional): Check if the path exists. Defaults to False.
        abs_path (bool, optional): Return the absolute path. Defaults to True.
        resolve (bool, optional): Resolve the path. Defaults to False.

    Returns:
        List[str]: List of paths.
    """
    if isinstance(path, (str, Path)):
        path = [path]
    paths: list[str] = []
    for p in path:
        p: str | None = clean_path(path=p, must_exist=must_exist, abs_path=abs_path, resolve=resolve)
        if p and p not in paths:
            paths.append(p)


def format_paths(
    paths: Union[List[str], str],
    fmt: Literal["path", "list", "json", "yaml", "toml"],
    pathsep: str = os.pathsep,
) -> str:
    """
    Format the paths.

    Args:
        paths (List[str]): List of paths.
        fmt (Literal['path', 'list', 'json']): Output format.

    Returns:
        str: Formatted paths.
    """
    if isinstance(paths, str):
        paths = paths.split(pathsep)
    paths = [p.strip() for p in paths if p.strip()]
    fmt = str(fmt).lower()
    if fmt == "path":
        return pathsep.join(paths)
    elif fmt == "list":
        return "\n".join(paths)
    elif fmt == "json":
        return json.dumps(paths, indent=2)
    elif fmt == "yaml":
        return yaml.dump(paths, default_flow_style=False, sort_keys=False)
    elif fmt == "toml":
        return toml.dumps(paths, sort_keys=False)
    else:
        raise ValueError(
            f"Invalid format: '{fmt}'. Must be one of 'path', 'list', 'json', 'yaml', 'toml'."
        )


@app.command()
def clean(
    path: Annotated[
        str,
        typer.Argument(
            help="$PATH to process", envvar="PATH", metavar="PATH", show_envvar=True
        ),
    ],
    fmt: Annotated[
        Format,
        typer.Option(
            "-f",
            "--format",
            help="Output format",
            show_default=True,
            case_sensitive=False,
        ),
    ] = Format.path,
) -> None:
    """
    Process the PATH.

    Args:
        path (Annotated[str, typer.Argument, optional): _description_. Defaults to " to process", envvar="PATH", metavar="PATH", show_envvar=True)]=os.getenv("PATH").
        fmt (Annotated[Format, typer.Option, optional): _description_. Defaults to "Output format", default=Format.path, show_default=True, case_sensitive=False)]=Format.path.
    """
    paths: List[str] = path.split(os.pathsep)
    new_paths: List[str] = []
    for p in paths:
        p = clean_path(path=p, must_exist=True, abs_path=True)
        if p and p not in new_paths:
            new_paths.append(p)

    formatted_paths = format_paths(paths=new_paths, fmt=fmt)
    typer.echo(formatted_paths)


if __name__ == "__main__":
    app()