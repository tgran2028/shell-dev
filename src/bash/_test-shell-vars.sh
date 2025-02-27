#!/usr/bin/env bash

declare -a shells=('/usr/bin/zsh' '/usr/bin/bash' '/usr/bin/fish')
declare -a methods=('source', 'execute')

_eof='EOF'

tf=$TEMPDIR/test-shell-vars-script.sh
echo "$tf"

cat << EOF | tee "$tf" > /dev/null
\$!/bin/bash

p1=\${1:SHELL_NAME}
p2=\${2:METHOD_NAME}

# Test matrix for variable values with:
# - different shells: ${shells[@]}
# - different methods: ${methods[@]}

cat << $_eof
# ----------------------------------------
# shell: \$p1  method: \$p2
# ----------------------------------------
'O': \$0
BASH_VERSION: \$BASH_VERSION
ZSH_VERSION: \$ZSH_VERSION
'BASH_SOURCE[0]': \${BASH_SOURCE[0]}
# ----------------------------------------
$_eof

EOF

chmod +x "$tf"

for __SHELL in "${shells[@]}"; do
  for __METHOD in "${methods[@]}"; do
    export SHELL_NAME=$(echo "$__SHELL" | awk -F'/' '{print $NF}')
    export METHOD_NAME=$__METHOD

    if [[ $__METHOD == 'source' ]]; then
      exec "$__SHELL" -c ". $tf"
    elif [[ $__METHOD == 'execute' ]]; then
      exec "$__SHELL" -c "$tf '$SHELL_NAME' $METHOD_NAME"
    fi
  done
done
