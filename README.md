# ZStack Support Codex Marketplace

Codex marketplace for the ZStack Support Agent plugin.

## Install

From this repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\plugins\zstack-support\scripts\install.ps1
```

Or install manually:

```powershell
codex plugin marketplace add .
codex plugin add zstack-support@zstack-support-local
```

For Git-based distribution:

```powershell
codex plugin marketplace add <owner>/<repo> --ref main
codex plugin add zstack-support@zstack-support-local
```

## Credentials

The plugin does not store credentials. Configure these as Windows user or machine environment variables before using MCP-backed lookup:

```text
GITHUB_MCP_TOKEN
ZSTACK_BBS_AUTHORIZATION
TAVILY_HIKARI_TOKEN
ATLASSIAN_BASIC_AUTH
ATLASSIAN_AUTHORIZATION
```

`ZSTACK_BBS_AUTHORIZATION` must contain the full Authorization header value, for example:

```text
Basic <base64(username:password)>
```

Restart Codex or open a new thread after changing environment variables.

`TAVILY_HIKARI_TOKEN` is used only for the Tavily external web-search MCP. Tavily results are public/vendor references for Linux, Windows, Red Hat, Ubuntu, kernel, QEMU/KVM, libvirt, Ceph, GPU drivers, and other non-ZStack topics. Treat them as E3 external references: useful for hypotheses and validation ideas, but not customer evidence and not sufficient to close an incident alone.

`ATLASSIAN_BASIC_AUTH` is the source value for the read-only shared `zstack_atlassian_shared` MCP. Set it to `base64(username:password)` without the `Basic ` prefix; `scripts\install.ps1` derives `ATLASSIAN_AUTHORIZATION=Basic <base64>` because Codex `env_http_headers` requires the complete header value. The shared MCP URL is fixed to `http://172.18.250.27:3340/mcp` in `.mcp.json`; do not store real values in this repository.

## Verify

```powershell
codex plugin list
codex mcp list
```

Expected MCP servers:

```text
github
zstack-bbs
tavily_hikari
zstack_atlassian_shared
```

Run the plugin skill `zstack-support:连通检查` for the full read-only smoke test.

## Update

```powershell
codex plugin marketplace upgrade zstack-support-local
codex plugin add zstack-support@zstack-support-local
```

For local development, update `.codex-plugin/plugin.json` with a cachebuster version such as `2.9.6+codex.local-YYYYMMDDHHMMSS`, then reinstall the plugin.
