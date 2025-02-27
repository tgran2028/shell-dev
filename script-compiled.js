#!/usr/bin/env node

// get fs
'use strict';

var fs = require('fs');
var path = require('path');
var program = require('commander');
// Removed: const chalk = require('chalk');
var shell = require('shelljs');
var inquirer = require('inquirer');
var yaml = require('js-yaml');
var json = require('json');
var jsonc = require('jsonc-parser');
var prettier = require('prettier');

var _require = require('prettier');

var Options = _require.Options;

var _require2 = require('child_process');

var execSync = _require2.execSync;
var spawn = _require2.spawn;

var _require3 = require('readline');

var createInterface = _require3.createInterface;

var _require4 = require('http');

var get = _require4.get;

/**
 * Convert environment to object
 * 
 * @param {object} env 
 * @returns {object} 
 */
function envToObject(env) {
  return Object.keys(env || {}).reduce(function (acc, key) {
    acc[key] = process.env[key];
    return acc;
  }, {});
}

// Create prettier options obj
var prettierOptions = {
  parser: 'json',
  printWidth: 120,
  tabWidth: 2,
  singleQuote: true,
  trailingComma: 'all',
  bracketSpacing: true,
  semi: false
};

prettier.resolveConfig(process.cwd()).then(function (options) {
  Object.assign(prettierOptions, options);
});

function resolvePromise(promise) {
  return promise.then(function (data) {
    return [null, data];
  })['catch'](function (err) {
    return [err];
  });
};

//# sourceMappingURL=script-compiled.js.map