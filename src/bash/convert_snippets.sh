#!/bin/bash

SNIPPETS_DIR="${1:-$HOME/.config/code-insiders/User/snippets}"
# Directory containing snippet files
SHELL_SNIPPET_DIR="$SNIPPETS_DIR/shellscript.d"
# Main JSON file
MAIN_JSON="$SNIPPETS_DIR/shellscript.json"

# Ensure MAIN_JSON exists
if [ ! -f "$MAIN_JSON" ]; then
  echo "{}" > "$MAIN_JSON"
fi

cp -f "$MAIN_JSON" "${MAIN_JSON/.json/.json.bak}" > /dev/null 2>&1
# Read the content of MAIN_JSON
main_json_content="$(jq -Mc '.' "$MAIN_JSON")"

# Iterate over all JSON files in SNIPPET_DIR
for file in "$SHELL_SNIPPET_DIR"/*.json; do
  # Skip if no JSON files are found
  [ -e "$file" ] || continue

  # Read the content of the current JSON file
  snippet_content=$(cat "$file")

  # Merge snippet_content into main_json_content
  main_json_content=$(jq -s '.[0] * .[1]' <(echo "$main_json_content") <(echo "$snippet_content"))
done

# Update MAIN_JSON with the merged content
echo "$main_json_content" > "$MAIN_JSON"

# Save each object in MAIN_JSON as a separate JSON file in SNIPPET_DIR
echo "$main_json_content" | jq -c 'to_entries[]' | while read -r entry; do
  key=$(echo "$entry" | jq -r '.key')
  value=$(echo "$entry" | jq -c '.value')
  filename=$(echo "$key" | tr -c '[:alnum:]' '_' | tr '[:upper:]' '[:lower:]').json

  # Skip if file already exists
  if [ ! -f "$SHELL_SNIPPET_DIR/$filename" ]; then
    echo "{\"$key\": $value}" > "$SHELL_SNIPPET_DIR/$filename"
  fi

done
