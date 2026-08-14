#!/usr/bin/env bash
# =============================================================================
# install-mcpc.sh
# Installs the @apify/mcpc CLI client and generates mcp.json for this project.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MCP_JSON="$PROJECT_ROOT/mcp.json"

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
# Prerequisites check
# ---------------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
  error "Docker is not installed or not in PATH."
  error "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
  exit 1
fi
success "Docker found: $(docker --version)"

# ---------------------------------------------------------------------------
# Install mcpc (idempotent)
# ---------------------------------------------------------------------------
if command -v mcpc &>/dev/null; then
  success "mcpc is already installed: $(mcpc --version 2>/dev/null || echo 'version unknown')"
else
  info "Installing mcpc via npm..."

  if ! command -v npm &>/dev/null; then
    error "npm is not installed or not in PATH."
    error "Install Node.js >= 18 from https://nodejs.org"
    exit 1
  fi

  if ! npm install -g @apify/mcpc; then
    error "npm installation failed."
    error "Ensure Node.js >= 18 is installed: https://nodejs.org"
    exit 1
  fi

  success "mcpc installed successfully."
fi

# ---------------------------------------------------------------------------
# Generate mcp.json (idempotent)
# ---------------------------------------------------------------------------
if [[ -f "$MCP_JSON" ]]; then
  warn "mcp.json already exists at $MCP_JSON — skipping generation."
  warn "Delete it and re-run this script to regenerate."
else
  info "Generating mcp.json at $MCP_JSON..."

  cat > "$MCP_JSON" <<'EOF'
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
    }
  }
}
EOF

  success "mcp.json generated."
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
echo -e "       # then edit .env with your Atlassian credentials"
echo ""
echo -e "  ${YELLOW}2.${NC} Pull the MCP Atlassian image (first time only):"
echo -e "       docker pull ghcr.io/sooperset/mcp-atlassian:latest"
echo ""
echo -e "  ${YELLOW}3.${NC} Connect mcpc to the server:"
echo -e "       mcpc connect mcp.json:mcp-atlassian @atlassian"
echo ""
echo -e "  ${YELLOW}4.${NC} List available tools:"
echo -e "       mcpc @atlassian tools-list"
echo ""
echo -e "  ${YELLOW}5.${NC} Run a test query:"
echo -e "       mcpc @atlassian tools-call jira_search_issues '{\"jql\": \"assignee = currentUser()\"}'"
echo ""
echo -e "${GREEN}Done!${NC}"
