#!/usr/bin/env bash
# =============================================================================
# install-mcp-cli.sh
# Installs the mcp-cli tool (https://github.com/philschmid/mcp-cli)
# and generates mcp_servers.json for this project.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_SERVERS_JSON="$PROJECT_ROOT/mcp_servers.json"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Prerequisites check: Docker
# ---------------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
  error "Docker is not installed or not in PATH."
  error "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
  exit 1
fi
success "Docker found: $(docker --version)"

# ---------------------------------------------------------------------------
# Prerequisites check: curl
# ---------------------------------------------------------------------------
if ! command -v curl &>/dev/null; then
  error "curl is not installed or not in PATH."
  error "Install curl: https://curl.se/download.html"
  exit 1
fi
success "curl found: $(curl --version | head -1)"

# ---------------------------------------------------------------------------
# Install mcp-cli (idempotent)
# ---------------------------------------------------------------------------
if command -v mcp-cli &>/dev/null; then
  success "mcp-cli is already installed: $(mcp-cli --version 2>/dev/null || echo 'version unknown')"
else
  info "Installing mcp-cli via install script..."

  if ! curl -fsSL https://raw.githubusercontent.com/philschmid/mcp-cli/main/install.sh | bash; then
    error "mcp-cli installation failed."
    error "Check your internet connection or install manually:"
    error "  curl -fsSL https://raw.githubusercontent.com/philschmid/mcp-cli/main/install.sh | bash"
    error "  or: bun install -g https://github.com/philschmid/mcp-cli"
    exit 1
  fi

  # Verify the install succeeded
  if ! command -v mcp-cli &>/dev/null; then
    error "mcp-cli was not found in PATH after installation."
    error "You may need to restart your shell or add the install location to PATH."
    exit 1
  fi

  success "mcp-cli installed successfully: $(mcp-cli --version 2>/dev/null || echo 'version unknown')"
fi

# ---------------------------------------------------------------------------
# Generate mcp_servers.json (idempotent)
# ---------------------------------------------------------------------------
if [[ -f "$MCP_SERVERS_JSON" ]]; then
  warn "mcp_servers.json already exists at $MCP_SERVERS_JSON — skipping generation."
  warn "Delete it and re-run this script to regenerate."
else
  info "Generating mcp_servers.json at $MCP_SERVERS_JSON..."

  cat > "$MCP_SERVERS_JSON" <<'EOF'
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--env-file",
        ".env",
        "ghcr.io/sooperset/mcp-atlassian:latest"
      ]
    },
    "figma": {
      "command": "npx",
      "args": [
        "-y",
        "figma-developer-mcp",
        "--stdio"
      ],
      "env": {
        "FIGMA_API_KEY": "${FIGMA_API_KEY}",
        "IMAGE_DIR": "${IMAGE_DIR}",
        "DO_NOT_TRACK": "1"
      }
    }
  }
}
EOF

  mkdir -p "$PROJECT_ROOT/images"
  touch "$PROJECT_ROOT/images/.gitkeep"
  success "mcp_servers.json generated."
fi

# ---------------------------------------------------------------------------
# Done — print next steps
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD} Setup complete! Next steps:${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo -e "  ${YELLOW}1.${NC} Make sure your ${BOLD}.env${NC} file exists and is populated:"
echo -e "       cp .env.example .env"
echo -e "       # then edit .env with your credentials (Atlassian, Figma)"
echo ""
echo -e "  ${YELLOW}2.${NC} Pull the MCP Atlassian image (first time only):"
echo -e "       docker pull ghcr.io/sooperset/mcp-atlassian:latest"
echo ""
echo -e "  ${YELLOW}3.${NC} List available servers and tools:"
echo -e "       mcp-cli"
echo ""
echo -e "  ${YELLOW}4.${NC} Inspect server tools:"
echo -e "       mcp-cli info mcp-atlassian"
echo -e "       mcp-cli info figma"
echo ""
echo -e "  ${YELLOW}5.${NC} Run test queries:"
echo -e "       mcp-cli call mcp-atlassian jira_search_issues '{\"jql\": \"assignee = currentUser()\"}'"
echo -e "       mcp-cli call figma get_file '{\"fileKey\": \"YOUR_FIGMA_FILE_KEY\"}'"
echo ""
echo -e "${GREEN}Done!${NC}"
