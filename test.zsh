#!/usr/bin/env zsh

echo -n '${(%):-%N}: '
echo "${(%):-%N}"
echo
echo -n '${(%):-%x}: '
echo "${(%):-%x}"

type funcstack
