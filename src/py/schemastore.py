#!/home/tim/.local/share/micromamba/envs/py-default-313/bin/python

import functools
import hashlib
import json
import time
from enum import StrEnum
from pathlib import Path
from typing import Any, Optional

import click
import platformdirs
import requests
import typer
import yaml
from click import Option
from pydantic import BaseModel, Field, HttpUrl
from rich.console import Console
from rich.syntax import Syntax
from rich.table import Table
from thefuzz import fuzz
from typing import Annotated

CATALOG_URL: str = "https://www.schemastore.org/api/json/catalog.json"


def get_cache_dir() -> Path:
    """
    Get the cache directory for the schemastore.

    Returns:
        Path: The cache directory.
    """
    cache_dir = platformdirs.user_cache_dir("schemastore")
    Path(cache_dir).mkdir(parents=True, exist_ok=True)
    return Path(cache_dir)


@functools.lru_cache
def download_json(
    url: str,
    allow_redirects: bool = True,
    timeout: int = 10,
    headers: dict[str, str] | None = None,
) -> dict:
    """
    Download a JSON file from a URL.

    Args:
        url (str): The URL of the JSON file.

    Returns:
        dict: The JSON data.
    """
    with requests.get(
        url, allow_redirects=allow_redirects, timeout=timeout, headers=headers
    ) as r:
        r.raise_for_status()
        return r.json()


def _save_json(data: dict, path: Path):
    """
    Save a dictionary to a JSON file.

    Args:
        data (dict): The dictionary to save.
        path (Path): The path to save the JSON file.
    """
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def _load_json(path: Path) -> dict:
    """
    Load a JSON file into a dictionary.

    Args:
        path (Path): The path to the JSON file.

    Returns:
        dict: The dictionary.
    """
    with open(path) as f:
        return json.load(f)


def _ensure_catalog(catalog_cache_file: str | Path | None = None) -> None:
    """
    Ensure the catalog is downloaded and up to date.
    """
    if not catalog_cache_file:
        cache_dir = get_cache_dir()
        catalog_cache_file = cache_dir / "catalog.json"
    else:
        catalog_cache_file = Path(catalog_cache_file).absolute()

    if not catalog_cache_file.exists():
        catalog = download_json(CATALOG_URL)
        _save_json(catalog, catalog_cache_file)

    # ensure from last 24 hours
    if time.time() - catalog_cache_file.stat().st_mtime > 86400:
        catalog = download_json(CATALOG_URL)
        _save_json(catalog, catalog_cache_file)


def get_catalog() -> dict:
    """
    Get the catalog of schemas.

    Returns:
        dict: The catalog.
    """
    _ensure_catalog()
    cache_dir = get_cache_dir()
    catalog_cache_file = cache_dir / "catalog.json"
    return _load_json(catalog_cache_file)


class Version(BaseModel):
    id: str
    url: HttpUrl


class Schema(BaseModel):
    name: str
    description: Optional[str] = None
    file_match: list[str] = Field(default_factory=list, alias="fileMatch")
    url: HttpUrl
    versions: dict[str, HttpUrl] = Field(default_factory=dict)

    @property
    def url_filename(self) -> str:
        return Path(str(self.url)).name

    @property
    def schema_data(self) -> dict:
        schemas_cache_dir = get_cache_dir() / "schemas"
        schemas_cache_dir.mkdir(parents=True, exist_ok=True)
        schema_cache_file = schemas_cache_dir / self.url_filename

        if schema_cache_file.exists():
            # if under 24 hours old
            if time.time() - schema_cache_file.stat().st_mtime < 86400:
                return _load_json(schema_cache_file)

        data = download_json(str(self.url))
        _save_json(data, schema_cache_file)
        return data.copy()

    def to_json(
        self,
        path: str | Path | None = None,
        indent: int = 2,
        default_name: bool = False,
    ) -> Optional[str]:
        if not path and default_name:
            path = Path.cwd().joinpath(self.url_filename)
        if not path and not default_name:
            return json.dumps(self.schema_data, indent=indent)
        with open(path, "w") as f:
            json.dump(self.schema_data, f, indent=indent)

    def to_yaml(
        self,
        path: str | Path | None = None,
        indent: int = 2,
        default_name: bool = False,
    ) -> Optional[str]:
        if not path and default_name:
            path = Path.cwd().joinpath(self.url_filename).with_suffix(".yaml")
        if not path and not default_name:
            return yaml.dump(
                self.schema_data,
                default_flow_style=False,
                sort_keys=False,
                indent=indent,
            )
        with open(path, "w") as f:
            yaml.dump(
                self.schema_data,
                f,
                default_flow_style=False,
                sort_keys=False,
                indent=indent,
            )

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "description": self.description,
            "fileMatch": self.file_match,
            "url": str(self.url),
            "versions": self.versions,
        }

    def __str__(self) -> str:
        return self.name

    def __repr__(self) -> str:
        return f"Schema(name={self.name}, url={self.url})"

    def __contains__(self, term: str) -> bool:
        return (
            term.lower() in self.name.lower()
            or term.lower() in self.description.lower()
        )

    def __eq__(self, other: "Schema") -> bool:
        return self.name == other.name and self.url == other.url

    def __hash__(self) -> int:
        h = hashlib.sha256()
        h.update(self.url.encode())
        return int(h.hexdigest(), 16)

    @classmethod
    def from_dict(cls, data: dict) -> "Schema":
        return cls(
            name=data["name"],
            description=data.get("description"),
            file_match=[str(item) for item in data.get("fileMatch", [])],
            url=data["url"],
            versions=data.get("versions", {}),
        )


@functools.lru_cache(maxsize=5000)
def get_schemas(as_obj: bool = True) -> list[dict[str, Any]] | list[Schema]:
    """
    Get the list of schemas.

    Returns:
        List[Dict[str, Any]]: The list of schemas.
    """
    catalog = get_catalog()
    schemas = catalog["schemas"]

    if as_obj:
        return [Schema.from_dict(schema) for schema in schemas]
    return schemas


def name_completion(incomplete: str) -> list[str]:
    """
    Click completion function for schema names.
    """
    schemas = get_schemas(as_obj=False)
    names = [schema["name"] for schema in schemas]
    names = sorted(list(set(names)))
    return [name for name in names if incomplete.lower() in name.lower()]


def get_schema(
    name: str, raw: bool = False, raise_error: bool = False
) -> Schema | None:
    """
    Get a schema by name.

    Args:
        name (str): The name of the schema.

    Returns:
        Schema: The schema.
    """
    schemas = get_schemas(as_obj=False)
    for schema in schemas:
        if schema["name"].lower() == name.lower():
            return (
                schema
                if raw
                else Schema(
                    name=schema["name"],
                    description=schema.get("description"),
                    file_match=schema.get("fileMatch", []),
                    url=schema["url"],
                    versions=schema.get("versions", {}),
                )
            )

    if raise_error:
        raise ValueError(f"Schema '{name}' not found.")


def fuzzy_search(name: str) -> Schema:
    schemas = get_schemas(as_obj=True)
    schema_names = [s.name for s in schemas]

    result = fuzz.partial_token_set_ratio(name, schema_names)
    return result


app = typer.Typer(
    name="schemastore",
    help="A CLI for the SchemaStore.",
    add_completion=True,
    no_args_is_help=True,
)


class OutputFormat(StrEnum):
    JSON = "json"
    YAML = "yaml"
    LIST = "list"
    TABLE = "table"


class SingleObjectFormat(StrEnum):
    JSON = "json"
    YAML = "yaml"


def get_console() -> Console:
    c: Console = Console()
    return c


@app.command(
    "list",
    help="List all schemas names.",
)
def list_schemas(
    names: Annotated[
        bool, typer.Option("-n", "--names", help="List only names.")
    ] = False,
    fmt: Annotated[
        OutputFormat, typer.Option("-f", "--format", help="Output format.")
    ] = OutputFormat.TABLE,
):
    """
    List all schemas names.
    """
    console = get_console()

    schemas = get_schemas(as_obj=True)
    if names:
        schema_names = sorted([s.name for s in schemas])
        if fmt == OutputFormat.JSON:
            data = json.dumps(schema_names, indent=2)
            s = Syntax(data, lexer="json", line_numbers=False)
            console.print(s)
        elif fmt == OutputFormat.YAML:
            data = yaml.dump(schema_names, default_flow_style=False, sort_keys=False)
            s = Syntax(data, lexer="yaml", line_numbers=False)
            console.print(s)
        elif fmt == OutputFormat.LIST:
            for name in schema_names:
                console.print(name)
        elif fmt == OutputFormat.TABLE:
            table = Table(title="Schema Names")
            table.add_column("Name")
            for name in schema_names:
                table.add_row(name)
            console.print(table)
    else:
        if fmt == OutputFormat.JSON:
            data = json.dumps([s.to_dict() for s in schemas], indent=2)
            s = Syntax(data, lexer="json", line_numbers=False)
            console.print(s)
        elif fmt == OutputFormat.YAML:
            data = yaml.dump(
                [s.to_dict() for s in schemas],
                default_flow_style=False,
                sort_keys=False,
            )
            s = Syntax(data, lexer="yaml", line_numbers=False)
            console.print(s)
        elif fmt == OutputFormat.LIST:
            for schema in schemas:
                console.print(schema)
        elif fmt == OutputFormat.TABLE:
            table = Table(title="Schemas")
            table.highlight = True
            table.add_column("Name")
            table.add_column("Description")
            table.add_column("URL")
            for schema in schemas:
                table.add_row(schema.name, schema.description, str(schema.url))
            console.print(table)


@app.command("search", help="Search for a schema by name.")
def search_schema(
    name: Annotated[
        str,
        typer.Argument(
            ...,
            help="The name of the schema to search for.",
            autocompletion=name_completion,
        ),
    ],
    fuzzy: Annotated[bool, typer.Option("--fuzzy", help="Fuzzy search.")] = False,
    fmt: Annotated[
        OutputFormat, typer.Option("-f", "--format", help="Output format.")
    ] = OutputFormat.YAML,
    indent: Annotated[
        int, typer.Option("-i", "--indent", help="Indentation level.")
    ] = 2,
    raw: Annotated[
        bool, typer.Option("-r", "--raw", help="Show raw schema data.")
    ] = False,
) -> None:
    """
    Search for a schema by name.
    """
    console = get_console()

    if fuzzy:
        result = fuzzy_search(name)
    else:
        schemas = get_schemas(as_obj=False)
        result = [s for s in schemas if name.lower() in s["name"].lower()]
        

    if not result:
        typer.Exit(code=1)

    if fmt == OutputFormat.JSON:
        data = json.dumps(result, indent=indent)
        if raw:
            typer.echo(data)
            return
        s = Syntax(data, lexer="json", line_numbers=False)
        console.print(s)
    elif fmt == OutputFormat.YAML:
        data = yaml.dump(
            result, default_flow_style=False, sort_keys=False, indent=indent
        )
        if raw:
            typer.echo(data)
            return
        s = Syntax(data, lexer="yaml", line_numbers=False)
        console.print(s)
    elif fmt == OutputFormat.LIST:
        console.print(["\n".join(s["name"] for s in result)])
    elif fmt == OutputFormat.TABLE:
        table = Table(title="Schema")
        table.add_column("Name")
        table.add_column("Description")
        table.add_column("URL")
        for schema in result:
            table.add_row(schema["name"], schema.get("description", ""), schema["url"])
        console.print(table)


@app.command("show", help="Show a schemastore entry.")
def show_entry(
    name: Annotated[
        str,
        typer.Argument(
            ...,
            help="The name of the schema to show.",
            autocompletion=name_completion,
            case_sensitive=False,
            shell_complete=True,
            atomic=True,
            parser=None,
        ),
    ],
    fmt: Annotated[
        SingleObjectFormat, typer.Option("-f", "--format", help="Output format.")
    ] = SingleObjectFormat.JSON,
    raw: Annotated[
        bool, typer.Option("-r", "--raw", help="Show raw schema data.")
    ] = False,
    indent: Annotated[
        int, typer.Option("-i", "--indent", help="Indentation level.")
    ] = 2,
):
    """
    Show a schemastore entry.
    """
    console = get_console()

    schema = get_schema(name)
    if fmt == SingleObjectFormat.JSON:
        data = json.dumps(schema.schema_data, indent=indent)
        if raw:
            typer.echo(data)
            return

        s = Syntax(data, lexer="json", line_numbers=False)
        console.print(s)
    elif fmt == SingleObjectFormat.YAML:
        data = yaml.dump(
            schema.schema_data, default_flow_style=False, sort_keys=False, indent=indent
        )
        if raw:
            typer.echo(data)
            return
        s = Syntax(data, lexer="yaml", line_numbers=False)
        console.print(s)
    elif fmt == OutputFormat.LIST:
        console.print(schema)
    else:
        raise ValueError(f"Invalid output format: {fmt}")


@app.command("schema", help="Get a schema by name.")
def get_schema_entry(
    name: Annotated[
        str,
        typer.Argument(
            ..., help="The name of the schema to get.", autocompletion=name_completion
        ),
    ],
    fmt: Annotated[
        SingleObjectFormat, typer.Option("-f", "--format", help="Output format.")
    ] = SingleObjectFormat.JSON,
    raw: Annotated[
        bool, typer.Option("-r", "--raw", help="Show raw schema data.")
    ] = False,
    indent: Annotated[
        int, typer.Option("-i", "--indent", help="Indentation level.")
    ] = 2,
):
    """
    Get a schema by name.
    """
    console = get_console()

    schema = get_schema(name)
    data = schema.schema_data

    if fmt == SingleObjectFormat.JSON:
        data = json.dumps(data, indent=indent)
        if raw:
            typer.echo(data)
            return
        s = Syntax(data, lexer="json", line_numbers=False)
        console.print(s)
    elif fmt == SingleObjectFormat.YAML:
        data: str = yaml.dump(
            data, default_flow_style=False, sort_keys=False, indent=indent
        )
        if raw:
            typer.echo(data)
            return
        s = Syntax(data, lexer="yaml", line_numbers=False)
        console.print(s)
    else:
        raise ValueError(f"Invalid output format: {fmt}")


@app.command("save", help="Save a schema to a file.")
def save_schema(
    name: Annotated[
        str,
        typer.Argument(
            ..., help="The name of the schema to save.", autocompletion=name_completion
        ),
    ],
    outfile: Annotated[
        Optional[str],
        typer,
        Option("-o", "--outfile", help="The output file.", type=click.File("w")),
    ] = None,
):
    """
    Save a schema to a file.
    """
    console = get_console()

    schema = get_schema(name)
    assert isinstance(schema, Schema)

    if outfile:
        out: Path = Path(str(outfile))
    else:
        out = Path(schema.url_filename)

    schema.to_json(out)
    console.print(str(out))


if __name__ == "__main__":
    app()
