#!/usr/bin/python3

import os
import sys
from pathlib import Path
import typer
from typer import Argument, Option, Typer, Exit, Context, BadParameter, FileTextWrite
from typing import LiteralString, Literal
import httpx
import zipfile
import re


BASE_URL: str = "https://clients2.google.com/service/update2/crx"
CHROME_EXT_MIMETYPE = "application/x-chrome-extension"


app = typer.Typer(
    name="dl-chrome-ext",
    help="Download a Chrome extension from the Chrome Web Store.",
    add_completion=True,
    no_args_is_help=True,
)


def validate_chrome_ext_id(ext_id: str) -> bool:
    """
    Extension ID. This is the 32-character word in a Chrome Web Store URL

    - 32 lowercase alphanumeric characters (a-p)

    Args:
        ext_id (str): The extension ID to validate.

    Returns:
        bool: True if the ID is valid, False otherwise.
    """
    pattern = r"^[a-z0-9]{32}$"
    return bool(re.match(pattern, ext_id))


def build_chrome_crx_params(
    ext_id: str,
    os: Literal["linux", "mac", "win", "cros", "openbsd", "android"] = "linux",
    arch: Literal["x86-64", "arm", "x86-32"] = "x86-64",
    nacl_arch: Literal["x86-64", "arm", "x86-32"] | None = None,
    accept_format: Literal["crx2", "crx3", "crx2,crx3"] = "crx2,crx3",
) -> dict[str, str]:
    """
    Build a dictionary for a Chrome CRX extension fetch query.

    Args:
        ext_id (str): The extension ID.

    Returns:
        dict: Dictionary of query parameters.
    """
    return {
        "response": "redirect",
        "os": os,
        "arch": arch,
        "os_arch": arch if nacl_arch is None else nacl_arch,
        "nacl_arch": nacl_arch if nacl_arch is not None else "x86-64",
        "prod": "chromiumcrx",
        "prodchannel": "unknown",
        "prodversion": "9999.0.9999.0",
        "acceptformat": accept_format,
        "x": f"id={ext_id}&uc",
    }


def get_chrome_extension(ext_id: str, outdir: Path | str = None) -> Path:
    """
    Download a Chrome extension and save it to the specified path.

    Args:
        ext_id (str): The extension ID.
        output_path (Path): The path where the extension will be saved.
    """

    if not validate_chrome_ext_id(ext_id):
        raise ValueError(
            f"Invalid Chrome extension ID: {ext_id}. It must be a 32-character lowercase alphanumeric string."
        )

    params: dict[str, str] = build_chrome_crx_params(ext_id)
    response: httpx.Response = httpx.get(BASE_URL, params=params, follow_redirects=True)
    response.raise_for_status()

    if outdir is None:
        outdir = Path(os.getcwd()).resolve()
    else:
        outdir = Path(outdir).resolve()
    assert isinstance(outdir, Path), "Output directory must be a Path object."

    outfile = outdir.joinpath(ext_id).with_suffix(".crx")
    with open(outfile, "wb") as f:
        f.write(response.content)

    return outfile


