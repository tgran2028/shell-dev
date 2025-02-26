#!/usr/bin/env bash

__env_json() {
  local -a _args
  # set yq args 
  if [[ $# -gt 0 ]]; then
    _args=( "$@" )
  else
    _args=(
      '--output-format' 'json'
      '--prettyPrint'
      '-M'
      '--indent' 2
      '.env'
      )
  fi
  # dump env to json
  python3 -c '
import os,sys,json;
env=dict(os.environ);
env_json={
  "env": {
    k: env[k]
    for k in
    sorted(list(env.keys()))
  }
};
sys.stdout.write(
  f"\n{json.dumps(env_json,indent=2)}\n"
);
' | yq -p json "${_args[@]}"
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  __env_json "$@"
fi

