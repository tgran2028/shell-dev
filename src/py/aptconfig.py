#!/usr/bin/python3

import argparse
import json
import sys

import apt_pkg
import yaml
from rich import box
from rich.console import Console
from rich.table import Table
from typing import Any, TypeAlias

Config: TypeAlias = dict[str, str | int | bool | None]

def parse_value(value: Any) -> str | int | bool | None:
    if not value.strip():
        return None
    if value.lower() in ["true", "false"]:
        return value.lower() == "true"
    value = str(value)
    if value.isdigit():
        return int(value)
    return value


def get_config() -> Config:
    conf = {k: apt_pkg.config.get(k) for k in apt_pkg.config.keys()}
    conf = {k: parse_value(v) for k, v in conf.items()}
    return conf


def format_table(conf: Config) -> None:
    # Create rich console object
    console = Console(color_system="truecolor")

    tbl = Table(
        title="APT Configuration",
        show_header=True,
        header_style="bold magenta",
        show_lines=True,
        box=box.SIMPLE,
        caption="Current APT Configuration",
    )
    tbl.add_column(header="Key", justify="left", header_style="bold cyan")
    tbl.add_column(header="Value", justify="left", header_style="bold cyan")

    for k, v in conf.items():
        tbl.add_row(k, str(v))

    console.print(tbl)


def format_json(conf: Config) -> None:
    print(json.dumps(conf, indent=2), file=sys.stdout)


def format_yaml(conf: Config) -> None:
    print(
        yaml.dump(conf, default_flow_style=False, indent=2, sort_keys=False),
        file=sys.stdout,
    )


def main() -> None:
    apt_pkg.init()
    parser = argparse.ArgumentParser(description="Show APT configuration")
    parser.add_argument(
        "-f",
        "--format",
        choices=["table", "json", "yaml"],
        default="table",
        help="Output format",
    )
    args = parser.parse_args()
    conf = get_config()
    if args.format == "table":
        format_table(conf)
    elif args.format == "json":
        format_json(conf)
    elif args.format == "yaml":
        format_yaml(conf)


if __name__ == "__main__":
    main()
