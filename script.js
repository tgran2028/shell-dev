#!/usr/bin/env node
// get fs
const fs = require('fs');
const path = require('path');
const program = require('commander');
// Removed: const chalk = require('chalk');
const shell = require('shelljs');
const inquirer = require('inquirer');
const yaml = require('js-yaml');
const json = require('json');
const jsonc = require('jsonc-parser');
const prettier = require('prettier');
const { Options } = require('prettier');
const { execSync, spawn } = require('child_process');
const { createInterface } = require('readline');
const { get } = require('http');

/**
 * Convert environment to object
 * 
 * @param {object} env 
 * @returns {object} 
 */
function envToObject(env) {
  return Object.keys(env || {}).reduce((acc, key) => {
    acc[key] = process.env[key];
    return acc;
  }, {});
}


// Create prettier options obj
const prettierOptions = {
  parser: 'json',
  printWidth: 120,
  tabWidth: 2,
  singleQuote: true,
  trailingComma: 'all',
  bracketSpacing: true,
  semi: false,
};

prettier.resolveConfig(process.cwd()).then((options) => {
  Object.assign(prettierOptions, options);
});


function resolvePromise(promise) {
  return promise
    .then((data) => [null, data])
    .catch((err) => [err]);
};



