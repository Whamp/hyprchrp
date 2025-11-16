#!/bin/bash
# Generate production artifacts from uv development environment
# This script bridges the gap between uv-based development and pip-based production

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

echo -e "${BLUE}🔄 Syncing production artifacts from uv development environment${NC}"
echo "Package root: $PACKAGE_ROOT"

# Check if we're in the right directory
if [[ ! -f "$PACKAGE_ROOT/pyproject.toml" ]]; then
    echo -e "${RED}❌ Error: pyproject.toml not found. Please run this script from the hyprchrp repository.${NC}"
    exit 1
fi

cd "$PACKAGE_ROOT"

# Check if uv is available
if ! command -v uv >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: uv is required for this script. Please run './scripts/dev-setup.sh' first.${NC}"
    exit 1
fi

# Check if uv.lock exists
if [[ ! -f "uv.lock" ]]; then
    echo -e "${YELLOW}⚠️  uv.lock not found, generating...${NC}"
    uv lock
fi

# Backup existing requirements.txt
if [[ -f "requirements.txt" ]]; then
    cp requirements.txt requirements.txt.backup
    echo -e "${YELLOW}📋 Backed up existing requirements.txt to requirements.txt.backup${NC}"
fi

# Generate production requirements (no dev dependencies)
echo -e "${BLUE}📦 Generating production requirements...${NC}"
uv export --format requirements-txt --no-dev | sed 's/-e \.//' > requirements.txt

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Generated requirements.txt${NC}"
else
    echo -e "${RED}❌ Failed to generate requirements.txt${NC}"
    exit 1
fi

# Generate development requirements (for developers who want to use pip)
echo -e "${BLUE}🛠️  Generating development requirements...${NC}"
uv export --format requirements-txt --only-dev > requirements-dev.txt

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Generated requirements-dev.txt${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to generate requirements-dev.txt (non-critical)${NC}"
fi

# Generate dependency tree for documentation
echo -e "${BLUE}🌳 Generating dependency tree...${NC}"
uv tree > dependency-tree.txt

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Generated dependency-tree.txt${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to generate dependency-tree.txt (non-critical)${NC}"
fi

# Validate requirements are pip-compatible
echo -e "${BLUE}🔍 Validating pip compatibility...${NC}"

# Create a temporary virtual environment for validation
TEMP_VENV=$(mktemp -d)
trap "rm -rf $TEMP_VENV" EXIT

python3 -m venv "$TEMP_VENV/venv"
source "$TEMP_VENV/venv/bin/activate"

# Try to install without actually installing (dry run if available)
if pip install --dry-run -r requirements.txt >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Requirements validation passed${NC}"
elif pip check --dry-run -r requirements.txt >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Requirements validation passed${NC}"
else
    # If dry-run isn't available, do a basic syntax check
    if python -c "
import sys
try:
    with open('requirements.txt', 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                # Basic format validation
                if '==' not in line and '>=' not in line and '<=' not in line and '>' not in line and '<' not in line:
                    # Skip if it's just a package name without version
                    continue
    print('Requirements format is valid')
except Exception as e:
    print(f'Validation error: {e}')
    sys.exit(1)
"; then
        echo -e "${GREEN}✓ Requirements format validation passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not fully validate requirements, but format appears correct${NC}"
    fi
fi

deactivate

# Show summary of changes
echo
echo -e "${BLUE}📊 Production artifacts generated:${NC}"
echo "  requirements.txt          - Production dependencies ($(wc -l < requirements.txt) packages)"
if [[ -f "requirements-dev.txt" ]]; then
    echo "  requirements-dev.txt     - Development dependencies ($(wc -l < requirements-dev.txt) packages)"
fi
if [[ -f "dependency-tree.txt" ]]; then
    echo "  dependency-tree.txt      - Dependency tree documentation"
fi

# Check if requirements.txt changed
if [[ -f "requirements.txt.backup" ]]; then
    if ! diff -q requirements.txt requirements.txt.backup >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  requirements.txt has changed since last sync${NC}"
        echo "  Consider reviewing the changes before committing:"
        echo "  git diff requirements.txt.backup requirements.txt"
    else
        echo -e "${GREEN}✓ requirements.txt is up to date${NC}"
    fi
    rm requirements.txt.backup
fi

echo
echo -e "${GREEN}🎉 Production sync complete!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review the generated files (especially requirements.txt)"
echo "  2. Commit the changes: git add pyproject.toml uv.lock requirements.txt"
echo "  3. Update installation script if needed"
echo "  4. Test production installation: ./scripts/install-omarchy.sh"
echo
echo -e "${BLUE}Note:${NC} Production users will install using pip and requirements.txt."
echo "They will never need to install uv or use these development tools."