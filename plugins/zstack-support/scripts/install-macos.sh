#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-macos.sh [options]

Options:
  --marketplace-root PATH   Marketplace root. Defaults to the parent of the
                            marketplace directory that contains this plugin.
  --plugin-root PATH        Plugin root containing .mcp.json. Defaults to the
                            parent directory when this script is under scripts/.
  --marketplace-name NAME   Marketplace name. Default: zstack-support-local
  --plugin-name NAME        Plugin name. Default: zstack-support
  --codex PATH              Codex executable path.
  --configure-env           Prompt for connector credentials with hidden input.
  --skip-existing           With --configure-env, keep existing launchctl values.
  --no-plugin-install       Only validate MCP and environment; skip codex plugin commands.
  -h, --help                Show this help.

Secret values are never printed. On macOS, connector credentials are injected
into the current GUI user session with launchctl setenv. Restart Codex or open a
new thread after changing values.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

info() {
  printf '%s\n' "$*"
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
plugin_root="$(cd -- "$script_dir/.." && pwd -P)"
default_marketplace_root="$(cd -- "$plugin_root/../.." 2>/dev/null && pwd -P || true)"

marketplace_root="${default_marketplace_root:-}"
marketplace_name="zstack-support-local"
plugin_name="zstack-support"
codex_exe="${CODEX_EXE:-}"
configure_env=0
skip_existing=0
plugin_install=1
marketplace_root_explicit=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --marketplace-root)
      [[ $# -ge 2 ]] || die "--marketplace-root requires a path"
      marketplace_root="$(cd -- "$2" && pwd -P)"
      marketplace_root_explicit=1
      shift 2
      ;;
    --plugin-root)
      [[ $# -ge 2 ]] || die "--plugin-root requires a path"
      plugin_root="$(cd -- "$2" && pwd -P)"
      default_marketplace_root="$(cd -- "$plugin_root/../.." 2>/dev/null && pwd -P || true)"
      if [[ "$marketplace_root_explicit" -eq 0 ]]; then
        marketplace_root="$default_marketplace_root"
      fi
      shift 2
      ;;
    --marketplace-name)
      [[ $# -ge 2 ]] || die "--marketplace-name requires a value"
      marketplace_name="$2"
      shift 2
      ;;
    --plugin-name)
      [[ $# -ge 2 ]] || die "--plugin-name requires a value"
      plugin_name="$2"
      shift 2
      ;;
    --codex)
      [[ $# -ge 2 ]] || die "--codex requires a path"
      codex_exe="$2"
      shift 2
      ;;
    --configure-env)
      configure_env=1
      shift
      ;;
    --skip-existing)
      skip_existing=1
      shift
      ;;
    --no-plugin-install)
      plugin_install=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

resolve_codex() {
  local candidate=""
  if [[ -n "$codex_exe" ]]; then
    [[ -x "$codex_exe" ]] || die "Codex executable is not executable: $codex_exe"
    printf '%s\n' "$codex_exe"
    return
  fi

  candidate="$(command -v codex 2>/dev/null || true)"
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return
  fi

  candidate="/Applications/Codex.app/Contents/Resources/codex"
  if [[ -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return
  fi

  die "Codex executable was not found. Pass --codex /path/to/codex."
}

validate_mcp_json() {
  local path="$1"
  python3 - "$path" <<'PY'
import json
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1]).resolve()
config_dir = path.parent
raw = path.read_text(encoding="utf-8-sig")
config = json.loads(raw)
servers = config.get("mcpServers")
if not isinstance(servers, dict):
    raise SystemExit("mcpServers is required by the current Codex plugin installer")

for server_name in servers:
    if not re.match(r"^[a-zA-Z0-9_-]+$", server_name):
        raise SystemExit(f"Invalid MCP server name {server_name!r}; use only letters, numbers, underscore, and hyphen")

github = servers.get("github") or {}
if github.get("bearer_token_env_var") != "GITHUB_MCP_TOKEN":
    raise SystemExit("github must use bearer_token_env_var=GITHUB_MCP_TOKEN")
if github.get("type") != "streamable_http":
    raise SystemExit("github must use type=streamable_http")
if "headers" in github:
    raise SystemExit("github must not use raw headers")

bbs = servers.get("zstack-bbs") or {}
if bbs.get("type") != "streamable_http":
    raise SystemExit("zstack-bbs must use type=streamable_http")
if (bbs.get("env_http_headers") or {}).get("Authorization") != "ZSTACK_BBS_AUTHORIZATION":
    raise SystemExit("BBS must use env_http_headers.Authorization=ZSTACK_BBS_AUTHORIZATION")
if (bbs.get("http_headers") or {}).get("X-MCP-Readonly") != "true":
    raise SystemExit("BBS must preserve X-MCP-Readonly=true")
if "headers" in bbs:
    raise SystemExit("BBS must not use raw headers")

tavily = servers.get("tavily_hikari") or {}
if tavily.get("type") != "streamable_http":
    raise SystemExit("tavily_hikari must use type=streamable_http")
if tavily.get("url") != "https://tavily.zopen1.com/mcp":
    raise SystemExit("tavily_hikari must use the approved Tavily MCP URL")
if tavily.get("bearer_token_env_var") != "TAVILY_HIKARI_TOKEN":
    raise SystemExit("tavily_hikari must use bearer_token_env_var=TAVILY_HIKARI_TOKEN")
if "headers" in tavily:
    raise SystemExit("tavily_hikari must not use raw headers")

if "zstack_atlassian" in servers:
    raise SystemExit("legacy zstack_atlassian MCP server is not allowed; use zstack_atlassian_shared")

atlassian = servers.get("zstack_atlassian_shared") or {}
if atlassian.get("type") != "streamable_http":
    raise SystemExit("zstack_atlassian_shared must use type=streamable_http")
if atlassian.get("url") != "http://172.18.250.27:3340/mcp":
    raise SystemExit("zstack_atlassian_shared must use the approved shared Atlassian MCP URL")
if atlassian.get("enabled") is not True:
    raise SystemExit("zstack_atlassian_shared must set enabled=true")
if (atlassian.get("http_headers") or {}).get("Accept") != "application/json, text/event-stream":
    raise SystemExit("zstack_atlassian_shared must preserve Accept=application/json, text/event-stream")
if (atlassian.get("env_http_headers") or {}).get("Authorization") != "ATLASSIAN_AUTHORIZATION":
    raise SystemExit("zstack_atlassian_shared must use env_http_headers.Authorization=ATLASSIAN_AUTHORIZATION")
for field in ("command", "args", "cwd", "env", "startup_timeout_sec", "tool_timeout_sec"):
    if field in atlassian:
        raise SystemExit(f"zstack_atlassian_shared must not use local adapter field {field!r}")
for legacy_script in ("scripts/zstack-atlassian-mcp.js", "scripts/zstack-atlassian-mcp.ps1"):
    if (config_dir / legacy_script).exists():
        raise SystemExit(f"legacy local Atlassian adapter script must be removed: {legacy_script}")

raw_without_allowed_refs = raw.replace("ATLASSIAN_AUTHORIZATION", "")
if re.search(r"github_pat_|Basic Ym|Bearer github_pat|\$\{", raw_without_allowed_refs):
    raise SystemExit("MCP config contains a concrete secret or unsupported variable interpolation")

print(f"Codex plugin MCP config OK: {path}")
PY
}

get_launch_env() {
  launchctl getenv "$1" 2>/dev/null || true
}

env_present() {
  local name="$1"
  local value=""
  value="$(get_launch_env "$name")"
  [[ -n "$value" ]]
}

set_launch_env_if_provided() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    info "Skipped: $name"
    return
  fi
  if [[ "$skip_existing" -eq 1 ]] && env_present "$name"; then
    info "Kept existing: $name"
    return
  fi
  launchctl setenv "$name" "$value"
  info "Set user launch variable: $name"
}

read_secret() {
  local prompt="$1"
  local value=""
  printf '%s' "$prompt" >&2
  stty -echo
  IFS= read -r value || true
  stty echo
  printf '\n' >&2
  printf '%s' "$value"
}

read_plain() {
  local prompt="$1"
  local value=""
  printf '%s' "$prompt" >&2
  IFS= read -r value || true
  printf '%s' "$value"
}

basic_authorization() {
  local username="$1"
  local password="$2"
  if [[ -z "$username" || -z "$password" ]]; then
    printf ''
    return
  fi
  printf 'Basic %s' "$(printf '%s:%s' "$username" "$password" | base64 | tr -d '\n')"
}

configure_environment() {
  info "ZStack Support Agent macOS environment setup"
  info "Secret values are accepted interactively and will not be printed."
  info "Press Enter to skip any item you do not want to set now."
  info ""

  local github_token tavily_token bbs_user bbs_password bbs_auth atlassian_user atlassian_password atlassian_auth

  github_token="$(read_secret "GitHub token for GITHUB_MCP_TOKEN: ")"
  set_launch_env_if_provided "GITHUB_MCP_TOKEN" "$github_token"

  tavily_token="$(read_secret "Tavily token for TAVILY_HIKARI_TOKEN: ")"
  set_launch_env_if_provided "TAVILY_HIKARI_TOKEN" "$tavily_token"

  bbs_user="$(read_plain "ZStack BBS username for ZSTACK_BBS_AUTHORIZATION: ")"
  bbs_password="$(read_secret "ZStack BBS password: ")"
  bbs_auth="$(basic_authorization "$bbs_user" "$bbs_password")"
  set_launch_env_if_provided "ZSTACK_BBS_AUTHORIZATION" "$bbs_auth"

  atlassian_user="$(read_plain "Jira/Confluence username for ATLASSIAN_AUTHORIZATION: ")"
  atlassian_password="$(read_secret "Jira/Confluence password: ")"
  atlassian_auth="$(basic_authorization "$atlassian_user" "$atlassian_password")"
  set_launch_env_if_provided "ATLASSIAN_AUTHORIZATION" "$atlassian_auth"
}

check_basic_shape() {
  local value="$1"
  [[ "$value" =~ ^Basic[[:space:]][^[:space:]]+$ ]] || return 1
  local encoded="${value#Basic }"
  local decoded=""
  decoded="$(printf '%s' "$encoded" | base64 -d 2>/dev/null || true)"
  [[ "$decoded" == *:* ]]
}

print_environment_snapshot() {
  local name value status
  info ""
  info "Current launchctl variable presence:"
  for name in GITHUB_MCP_TOKEN ZSTACK_BBS_AUTHORIZATION TAVILY_HIKARI_TOKEN ATLASSIAN_AUTHORIZATION; do
    value="$(get_launch_env "$name")"
    if [[ -z "$value" ]]; then
      status="missing"
    elif [[ "$name" == "GITHUB_MCP_TOKEN" ]]; then
      if [[ "$value" =~ ^(github_pat_|ghp_|gho_|ghu_|ghs_|ghr_) ]]; then
        status="present, format ok"
      else
        status="present, unusual GitHub token prefix"
      fi
    elif [[ "$name" == "ZSTACK_BBS_AUTHORIZATION" || "$name" == "ATLASSIAN_AUTHORIZATION" ]]; then
      if check_basic_shape "$value"; then
        status="present, format ok"
      else
        status="present, expected Basic <base64(username:password)>"
      fi
    else
      status="present"
    fi
    printf '  %-28s %s\n' "$name" "$status"
  done

  if env_present "ATLASSIAN_BASIC_AUTH"; then
    warn "ATLASSIAN_BASIC_AUTH exists. New installs should use ATLASSIAN_AUTHORIZATION only."
  fi
}

[[ -f "$plugin_root/.mcp.json" ]] || die "Plugin .mcp.json not found at: $plugin_root/.mcp.json"
[[ -n "$marketplace_root" && -d "$marketplace_root" ]] || die "Marketplace root was not found. Pass --marketplace-root PATH."

validate_mcp_json "$plugin_root/.mcp.json"
info "Atlassian shared MCP configured: zstack_atlassian_shared -> http://172.18.250.27:3340/mcp"

codex_exe="$(resolve_codex)"
info "Codex executable: $codex_exe"
info "Marketplace root: $marketplace_root"

if [[ "$configure_env" -eq 1 ]]; then
  configure_environment
fi

if [[ "$plugin_install" -eq 1 ]]; then
  "$codex_exe" plugin marketplace add "$marketplace_root"
  "$codex_exe" plugin add "${plugin_name}@${marketplace_name}"
fi

print_environment_snapshot

if [[ "$plugin_install" -eq 1 ]]; then
  "$codex_exe" mcp list
fi

info ""
info "Install complete. Restart Codex or open a new thread before running ZStackSupport:连通检查."
