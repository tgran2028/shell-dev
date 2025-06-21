#!/usr/bin/python3

import sys
import os
import subprocess
import tempfile as tf
from urllib.parse import urlparse
from pathlib import Path
import typer
import requests
import tempfile
from typing import Optional


app = typer.Typer()


def parse_deb_filename(url: str) -> str:
    """
    Parse the filename from a .deb file URL.

    Args:
        url (str): The URL of the .deb file.

    Returns:
        str: The filename extracted from the URL.
    """
    parsed = urlparse(url)
    name = parsed.path.split("/")[-1]
    if not name.endswith(".deb"):
        raise ValueError("The URL does not point to a .deb file.")

    return name


def get_default_output_dir() -> Path:
    """Return default directory for deb downloads."""
    return Path(tempfile.gettempdir()).resolve() / "deb-install"


def resolve_output_path(
    url: str, filename: Optional[str] = None, output_dir: Optional[str] = None
) -> Path:
    """Determine deb file path, handling filename and output_dir logic."""
    if not filename:
        filename = parse_deb_filename(url)
    if output_dir:
        dir_path = Path(output_dir).resolve()
        if dir_path.suffix == ".deb":
            filename = dir_path.name
            dir_path = dir_path.parent
    else:
        dir_path = get_default_output_dir()
    dir_path.mkdir(parents=True, exist_ok=True)
    return dir_path / filename


def download_file(url: str, dest_path: Path) -> None:
    """Download content from URL to dest_path with streaming."""
    with requests.get(url, stream=True, allow_redirects=True) as res:
        res.raise_for_status()
        with open(dest_path, "wb") as file:
            for chunk in res.iter_content(chunk_size=8192):
                file.write(chunk)


def download_debfile_url(
    url: str, filename: str | None = None, output_dir: str | None = None
) -> str:
    """
    Download a .deb file from a given URL using requests.
    """
    deb_path = resolve_output_path(url, filename, output_dir)
    if deb_path.exists():
        typer.echo(f"File {deb_path} already exists, skipping download.")
        return str(deb_path)

    download_file(url, deb_path)
    typer.echo(f"Downloaded {deb_path} from {url}")
    return str(deb_path)


def check_apt_pkg_is_installed(pkg_name: str) -> bool:
    """
    Check if a package is installed using dpkg.
    """
    try:
        subprocess.run(
            ["dpkg", "-s", pkg_name],
            check=True,
            sddtdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except subprocess.CalledProcessError:
        return False
