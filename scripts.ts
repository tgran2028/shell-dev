// import fs
import * as fs from "node:fs"
import { Command,  } from "https://esm.sh/commander";

const program = new Command();
// list contents of a directory
const files = Deno.readDirSync(".");

// cwd
let cwd = Deno.cwd();
console.log(cwd);

program.
    option('-d, --debug', 'output extra debugging').
    option('-s, --small', 'small pizza size').
    option('-p, --pizza-type <type>', 'flavour of pizza').
    option('-h', '--help', 'display help for command');



