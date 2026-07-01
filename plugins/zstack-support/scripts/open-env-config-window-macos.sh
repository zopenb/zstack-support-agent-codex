#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
install_script="$script_dir/install-macos.sh"

if [[ ! -f "$install_script" ]]; then
  printf 'ERROR: install-macos.sh not found next to this script.\n' >&2
  exit 1
fi

args=("--configure-env" "--no-plugin-install")
for arg in "$@"; do
  args+=("$arg")
done

quoted_script="$(printf '%q' "$install_script")"
quoted_args=""
for arg in "${args[@]}"; do
  quoted_args+=" $(printf '%q' "$arg")"
done

osascript <<EOF
tell application "Terminal"
  activate
  do script "$quoted_script$quoted_args"
end tell
EOF

printf 'Opened a visible Terminal window for secret input.\n'
printf 'Do not paste tokens or passwords into Codex chat.\n'
