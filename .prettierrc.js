// prettier.config.js, .prettierrc.js, prettier.config.cjs, or .prettierrc.cjs

/**
 * @see https://prettier.io/docs/en/configuration.html
 * @type {import("prettier").Config}
 */

const shOpts = {
    indent: 4,
    binaryNextLine: true,
    switchCaseIndent: true,
    spaceRedirects: true,
    keepPadding: true,
    minify: false,
    functionNextLine: false,
    experimentalWasm: true // experimental
}

const config = {
    trailingComma: "es5",
    tabWidth: 4,
    semi: false,
    singleQuote: true,
    printWidth: 89,
    plugins: [
        "prettier-plugin-sh",
        "@prettier/plugin-xml",
        "@prettier/plugin-ruby",
        "prettier-plugin-properties",
        "prettier-plugin-rust",
        "prettier-plugin-sql",
        'prettier-plugin-toml',
    ],
    ...shOpts
  };
  
  module.exports = config;
