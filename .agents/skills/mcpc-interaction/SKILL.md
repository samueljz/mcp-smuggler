---
name: mcpc-interaction
description: Instructs the agent on how to use the mcpc CLI to interact with Model Context Protocol (MCP) servers.
---

# MCP CLI (`mcpc`) Skill

This project allows you to interface with generic Model Context Protocol (MCP) servers using the `mcpc` CLI client.

## Interacting with MCP Servers via `mcpc`

You will use the `mcpc` CLI client to connect to MCP servers, discover their capabilities, and execute tools.

### 1. Connect to Servers
Use the following command to auto-discover configs (e.g., `../../../mcp.json`) in the current directory and launch all local stdio servers automatically:
```bash
mcpc connect --stdio
```
This command will establish the connections and output the names of the active sessions (e.g., `@mysession`). Take note of these session aliases, as you will need them to run subsequent commands.

*If you ever forget which sessions are active, run `mcpc` without arguments to list them.*

### 2. List Available Tools
To discover what operations you can perform for a connected session, list the available MCP tools:
```bash
mcpc @<session> tools-list
```
This will return a JSON list of tools along with their descriptions and expected arguments (input schema). Pay close attention to the `inputSchema` for each tool.

*Tip: You can also search for tools across all active sessions using `mcpc grep <pattern>`.*

### 3. Call a Tool
Once you have identified a tool to use and its required schema, use the `tools-call` command to execute it. 

**Syntax:**
```bash
mcpc @<session> tools-call <tool_name> '<json_arguments>'
```

**Example:**
```bash
mcpc @mysession tools-call perform_search '{"query": "example data", "limit": 10}'
```

## Guidelines for the Agent
1. **Discover First**: Always run `mcpc @<session> tools-list` when interacting with a new MCP server to understand its exact tool capabilities and input requirements.
2. **Use Valid JSON**: The `<json_arguments>` payload must be a valid JSON string. Be sure to correctly escape internal double quotes if wrapping the payload in single quotes for bash execution.
3. **Session State**: Your connections will remain active in the background. If a command fails due to a closed connection, re-run `mcpc connect --stdio` to restore all auto-discovered configurations.
