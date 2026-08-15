---
name: mcp-cli-interaction
description: Instructs the agent on how to use the mcp-cli tool to interact with Model Context Protocol (MCP) servers.
---

# MCP CLI (`mcp-cli`) Skill

This project allows you to interface with generic Model Context Protocol (MCP) servers using the [`mcp-cli`](https://github.com/philschmid/mcp-cli) tool.

## Interacting with MCP Servers via `mcp-cli`

`mcp-cli` is stateless and config-driven. It auto-discovers `mcp_servers.json` in the current directory (or `~/.config/mcp/mcp_servers.json` globally). No session connection step is required.

### 1. List Available Servers and Tools

Run `mcp-cli` from the project root (where `mcp_servers.json` lives) to see all configured servers and their tools:

```bash
mcp-cli

# With tool descriptions:
mcp-cli -d
```

### 2. Inspect a Server or Tool

To see all tools for a specific server:

```bash
mcp-cli info <server>
```

To see the full schema (parameters) for a specific tool:

```bash
mcp-cli info <server> <tool_name>
# or using slash syntax:
mcp-cli info <server>/<tool_name>
```

**Example:**

```bash
mcp-cli info mcp-atlassian
mcp-cli info mcp-atlassian jira_search_issues
```

### 3. Search Tools by Pattern

```bash
mcp-cli grep "<pattern>"

# With descriptions:
mcp-cli grep "*jira*" -d
```

### 4. Call a Tool

```bash
mcp-cli call <server> <tool_name> '<json_arguments>'
```

**Example:**

```bash
mcp-cli call mcp-atlassian jira_search_issues '{"jql": "assignee = currentUser()", "max_results": 10}'
```

**Stdin alternative** (avoids shell escaping issues with complex JSON):

```bash
echo '{"jql": "project = MYPROJ"}' | mcp-cli call mcp-atlassian jira_search_issues
```

**Pipe output with jq:**

```bash
mcp-cli call mcp-atlassian jira_search_issues '{"jql": "assignee = currentUser()"}' | jq '.content[0].text'
```

## Guidelines for the Agent

1. **No connection step needed**: Unlike session-based CLI tools, `mcp-cli` requires no upfront `connect` command. Just call `mcp-cli` from the directory containing `mcp_servers.json`.
2. **Discover first**: Always run `mcp-cli info <server> <tool_name>` when interacting with an unfamiliar tool to understand its exact parameters and required fields.
3. **Use stdin for complex JSON**: When JSON arguments contain single quotes, special characters, or long text, pipe JSON via stdin to avoid shell escaping issues.
4. **Config location matters**: Run `mcp-cli` commands from the project root so it auto-discovers `mcp_servers.json`. Alternatively, pass `-c <path>` to specify a config file explicitly.
