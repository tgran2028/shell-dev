# fzf-scripts

This is a collection of scripts I've written that use [fzf](https://github.com/junegunn/fzf)

Almost all of them require various tools from coreutils like `awk` `sed` `cut`, and probably make use of GNU extensions.

## [dkr](dkr)

an interactive wrapper around some docker commands

## [fv](fv)

Lists or searches for files and opens them with a command, defaults to `vim`. Kind of a shortcut for `vim $(ag 'foo' | fzf)`, lists files if no search string is given.

## [fzgit](fzgit)

Interactive git wrapper. Very much still a work in progress, but it has some very cool functions already.

_depends on `git` and `perl`_

## [fzbuku](fzbuku)

A small wrapper around [buku](https://github.com/jarun/Buku) to search bookmarks

## [fzmp](fzmp)

Lists and searches for songs in an MPD library by artist, album, or playlist. I wrote a [blog post](https://danielfgray.gitlab.io/computers/fzmp) about writing this script.

_depends on `mpc`_

## [fzmv](fzmv)

Interactively move files. It was originally just an experiment to see what it would be like to make a file explorer with fzf.

## [fzrepl](fzrepl)

runs stdin against programs like sed, awk, jq and shows the result in the preview window

## [ddgsearch](ddgsearch)

A wrapper around [ddgr](https://github.com/jarun/ddgr) to search the web using DuckDuckGo.
Accepts all `ddgr` command line arguments. For example, to search Wikipedia for "hello world":

```sh
ddgsearch \!w hello world
```

_depends on `jq` and `ddgr`_

## [igr](igr)

Interactive grep/rg wrapper

## [ix](ix)

Uploads files to [ix.io](http://ix.io) and allows listing and editing of uploads.

_depends on `curl`_

## [js](js)

Searches [npmjs.com](https://npmjs.com) and installs packages with `yarn` if available or `npm`.

_depends on npm and [jq](https://stedolan.github.io/jq/)_

## [pkgsearch](pkgsearch)

Searches repos and installs multiple packages. Currently works with Debian, Ubuntu and Arch, and experimental support for Fedora and Void.

## [pkgrm](pkgrm)

Lists and removes packages, optionally sorts by size.

_depends on `pacman`_

## [sshget](sshget)

Lists files from remote servers and `rsync`s them to the current directory

## [wifi](wifi)

List and connect to wifi networks

_depends on `nmcli`_

# Install

Currently there's no installation script, but if you clone the repo you can easily symlink the scripts here with something like:

```sh
cd /path/to/repo/fzf-scripts
find -maxdepth 1 -executable -type f -exec ln -s -t $HOME/.local/bin $PWD/fzf-scripts/{} \;
```

# Notable Mentions

- [forgit](https://github.com/wfxr/forgit) - a better version of fzgit
- [fzf-tab](https://github.com/Aloxaf/fzf-tab) - use fzf to tab-complete everything in your shell

# Legal

Copyright (C) 2023 Ronald Joe Record <ronaldrecord@gmail.com>
Copyright (C) 2016 Daniel F Gray <DanielFGray@gmail.com>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
