#!/home/tim/.local/share/micromamba/envs/py-default-313/bin/python

from io import StringIO
from pathlib import Path
from typing import Any

import click
from dotenv import dotenv_values
import rich 
from rich.console import Console
from rich.syntax import Syntax

from rich import print as rprint

# from traitlets import default




def to_shell(key: str, value: Any, export: bool = True) -> str:
    v = str(value).strip("'").strip('"')
    line_parts = ["export"] if export else []

    # v = v.strip("'")
    # # if numeric, don't quote, else shlex.quote
    if not v.isnumeric():
        v = f"'{v}'"

    line_parts.append(f"{key}={v}")
    return " ".join(line_parts)


def envfile_to_shell(path: str, export: bool = True, annotate: bool = True) -> str:
    env_file = Path(path)
    if not env_file.exists():
        raise FileNotFoundError(f"File {path} does not exist")

    values = dotenv_values(path, interpolate=True)
    output = StringIO()
    div = f"# {'-' * 80}"
    if annotate:
        output.write(f"{div}\n# Generated by envfile '{path}' to shell\n{div}\n")

    for key, value in values.items():
        output.write(f"{to_shell(key, value, export=export)}\n")
    if annotate:
        output.write(f"{div}\n")
    else:
        output.write("\n")

    return output.getvalue().strip() + "\n"


def envfile_to_dict(path: str) -> dict:
    env_file = Path(path)
    if not env_file.exists():
        raise FileNotFoundError(f"File {path} does not exist")

    data = dotenv_values(path, interpolate=True)
    return dict(data.items())


from click import Option, Parameter, Argument  # ignore: F401  # noqa: E402


# no_export = Option(
#     ["-ne", "--no-export"],
#     is_flag=True,
#     help="Add export to each line",
#     default=False,
#     flag_value=True,
#     default_value=False,
# )


@click.command(
    help="Convert .env file to shell script",
    no_args_is_help=True,
)
@click.argument("path", type=click.Path(exists=True, readable=True, dir_okay=False))
@click.option(
    "-ne",
    "--no-export",
    is_flag=True,
    help="Add export to each line",
    # default=False,
    flag_value=True,
)
@click.option("--annotate", is_flag=True, help="Add comments to the output")
@click.option(
    "-c", "--color", is_flag=True, help="Colorize the output. Disabled if output is redirected"
)
@click.option("-M", "--monochrome", is_flag=True, help="Disable color output", default=False)
@click.option(
    "-o",
    "--output",
    type=click.Path(writable=True, dir_okay=False),
    help="Output file. Default is stdout",
)
def cli(path: str, no_export: bool, annotate: bool, color: bool, monochrome: bool, output: str):
    if monochrome and color:
        raise click.UsageError("Cannot use both --color and --monochrome")
    elif monochrome:
        color = False
    elif color:
        monochrome = False
    elif output is not None:
        color = False
        monochrome = True
    else:
        color = True
        monochrome = False

    if output:
        dst = Path(output)


    console = Console(no_color=monochrome)


    shell_code = envfile_to_shell(path, export=not no_export, annotate=annotate)
    if output:
        with dst.open("w") as f:
            f.write(shell_code)
    elif color:
        console.print(Syntax(shell_code, "bash"))
    else:
        console.print(shell_code)

if __name__ == "__main__":
    cli()
