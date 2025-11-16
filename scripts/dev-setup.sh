#!/bin/bash
# Setup development environment for hyprchrp (Omarchy mise-first)
# This script creates a modern development workflow using mise

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 Setting up hyprchrp development environment (Omarchy mise-first)${NC}"
echo "Package root: $PACKAGE_ROOT"

# Check if we're in the right directory
if [[ ! -f "$PACKAGE_ROOT/pyproject.toml" ]]; then
    echo -e "${RED}❌ Error: pyproject.toml not found. Please run this script from the hyprchrp repository.${NC}"
    exit 1
fi

cd "$PACKAGE_ROOT"

# Ensure mise is available (guaranteed on Omarchy)
echo -e "${BLUE}🐍 Ensuring mise Python environment...${NC}"
mise python install
eval "$(mise activate bash)"
echo -e "${GREEN}✓ mise Python environment ready: $(mise where python)${NC}"

# Optional: Setup uv for enhanced development workflow
echo -e "${BLUE}⚡ Setting up uv for enhanced development (optional)...${NC}"
if command -v uv >/dev/null 2>&1; then
    echo -e "${GREEN}✓ uv is available: $(uv --version)${NC}"

    # Create uv virtual environment if doesn't exist
    if [[ ! -d ".venv" ]]; then
        echo -e "${BLUE}🏗️  Creating uv virtual environment...${NC}"
        uv venv
        echo -e "${GREEN}✓ Created .venv${NC}"
    fi

    # Install development dependencies with uv
    echo -e "${BLUE}📥 Installing development dependencies with uv...${NC}"
    uv pip install -e ".[dev]" || {
        echo -e "${YELLOW}⚠️  uv installation failed, continuing with mise-only setup${NC}"
    }
else
    echo -e "${YELLOW}⚠️  uv not available - using mise-only workflow${NC}"
    echo -e "${YELLOW}   Install uv for faster dependency management:${NC}"
    echo -e "${YELLOW}   curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
fi

# Generate production requirements if sync script exists
echo -e "${BLUE}🔄 Generating production requirements...${NC}"
if [[ -f "$SCRIPT_DIR/sync-production.sh" ]]; then
    "$SCRIPT_DIR/sync-production.sh" || {
        echo -e "${YELLOW}⚠️  sync-production.sh failed, continuing anyway${NC}"
    }
fi

# Setup pre-commit hooks if available
echo -e "${BLUE}🔧 Setting up development tools...${NC}"
if command -v uv >/dev/null 2>&1 && uv run pre-commit --version >/dev/null 2>&1; then
    uv run pre-commit install
    echo -e "${GREEN}✓ Pre-commit hooks installed${NC}"
elif mise exec -- pre-commit --version >/dev/null 2>&1; then
    mise exec -- pre-commit install
    echo -e "${GREEN}✓ Pre-commit hooks installed via mise${NC}"
fi

# Success message
echo
echo -e "${GREEN}🎉 Development environment setup complete!${NC}"
echo
echo -e "${BLUE}Development commands (mise-first):${NC}"
echo "  mise run hyprchrp           # Run hyprchrp"
echo "  mise run test              # Run tests"
echo "  mise run lint              # Lint code"
echo "  mise run format            # Format code"
echo "  mise run type-check        # Type checking"
echo "  mise run sync-prod         # Sync production requirements"
echo
echo -e "${BLUE}mise shortcuts:${NC}"
echo "  mise run r                 # Run hyprchrp"
echo "  mise run t                 # Run tests"
echo "  mise run l                 # Lint code"
echo "  mise run f                 # Format code"
echo
echo -e "${BLUE}Direct mise exec:${NC}"
echo "  mise exec -- python lib/main.py"
echo "  mise exec -- pytest"
echo "  mise exec -- black ."
echo "  mise exec -- ruff check ."
echo

if command -v uv >/dev/null 2>&1; then
    echo -e "${BLUE}Enhanced workflow (with uv):${NC}"
    echo "  uv run python lib/main.py     # Run hyprchrp (faster)"
    echo "  uv run pytest                 # Run tests (faster)"
    echo "  uv run black .                # Format code (faster)"
    echo "  uv add new-package            # Add dependency"
    echo "  ./scripts/sync-production.sh  # Update production requirements"
else
    echo -e "${YELLOW}💡 Install uv for enhanced development performance:${NC}"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

echo
echo -e "${BLUE}Note:${NC} mise manages Python version and environment. uv is optional but"
echo "recommended for faster dependency management. Production installations use"
echo "traditional pip/venv and never require these development tools."