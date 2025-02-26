#!/bin/bash

# zsh
mkdir -p ~/.zfunc                         && mdbook completions zsh        | tee ~/.zfunc/_mdbook > /dev/null
# bash
mkdir -p ~/.bash_completions              && mdbook completions bash       | tee ~/.bash_completions/mdbook > /dev/null
# fish
mkdir -p ~/.config/fish/completions       &&  mdbook completions fish      | tee ~/.config/fish/completions/mdbook.fish > /dev/null
# powershell
mkdir -p ~/.config/powershell/completions && mdbook completions powershell | tee ~/.config/powershell/completions/mdbook.ps1 > /dev/null