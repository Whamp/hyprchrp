#!/bin/bash
# Dependency management helper for hyprchrp using uv
# This script helps manage dependencies in development and syncs to production

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

# Function to show usage
show_usage() {
    echo -e "${BLUE}Usage: $0 [command] [options]${NC}"
    echo
    echo "Commands:"
    echo "  add <package>          Add a new dependency"
    echo "  add-dev <package>      Add a new development dependency"
    echo "  remove <package>       Remove a dependency"
    echo "  update [package]       Update dependencies (all or specific)"
    echo "  sync                   Sync production artifacts"
    echo "  tree                   Show dependency tree"
    echo "  check                  Check for dependency conflicts"
    echo "  help                   Show this help"
    echo
    echo "Examples:"
    echo "  $0 add requests>=2.28.0"
    echo "  $0 add-dev pytest-mock"
    echo "  $0 remove old-package"
    echo "  $0 update requests"
    echo "  $0 sync"
}

# Function to add dependency
add_dependency() {
    local package="$1"
    local dev_only="${2:-false}"

    echo -e "${BLUE}📦 Adding dependency: $package${NC}"

    if [[ "$dev_only" == "true" ]]; then
        uv add --dev "$package"
    else
        uv add "$package"
    fi

    echo -e "${GREEN}✓ Added $package${NC}"
    echo -e "${YELLOW}💡 Run '$0 sync' to update production artifacts${NC}"
}

# Function to remove dependency
remove_dependency() {
    local package="$1"

    echo -e "${BLUE}🗑️  Removing dependency: $package${NC}"

    uv remove "$package"

    echo -e "${GREEN}✓ Removed $package${NC}"
    echo -e "${YELLOW}💡 Run '$0 sync' to update production artifacts${NC}"
}

# Function to update dependencies
update_dependencies() {
    local package="${1:-}"

    if [[ -n "$package" ]]; then
        echo -e "${BLUE}🔄 Updating dependency: $package${NC}"
        uv add --upgrade "$package"
        echo -e "${GREEN}✓ Updated $package${NC}"
    else
        echo -e "${BLUE}🔄 Updating all dependencies...${NC}"
        uv sync --upgrade
        echo -e "${GREEN}✓ Updated all dependencies${NC}"
    fi

    echo -e "${YELLOW}💡 Run '$0 sync' to update production artifacts${NC}"
}

# Function to sync production
sync_production() {
    echo -e "${BLUE}🔄 Syncing production artifacts...${NC}"

    if [[ -f "$SCRIPT_DIR/sync-production.sh" ]]; then
        "$SCRIPT_DIR/sync-production.sh"
    else
        echo -e "${RED}❌ sync-production.sh not found${NC}"
        exit 1
    fi
}

# Function to show dependency tree
show_tree() {
    echo -e "${BLUE}🌳 Dependency tree:${NC}"
    uv tree
}

# Function to check dependencies
check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"

    # Check uv environment
    if ! command -v uv >/dev/null 2>&1; then
        echo -e "${RED}❌ uv not found. Please run './scripts/dev-setup.sh' first.${NC}"
        exit 1
    fi

    # Check for conflicts
    echo -e "${BLUE}Checking for dependency conflicts...${NC}"
    if uv pip check >/dev/null 2>&1; then
        echo -e "${GREEN}✓ No dependency conflicts found${NC}"
    else
        echo -e "${YELLOW}⚠️  Dependency conflicts detected:${NC}"
        uv pip check
    fi

    # Check if production sync is needed
    if [[ -f "uv.lock" && -f "requirements.txt" ]]; then
        echo -e "${BLUE}Checking if production sync is needed...${NC}"

        # Temporarily generate requirements and compare
        temp_requirements=$(mktemp)
        trap "rm -f $temp_requirements" EXIT

        uv export --format requirements-txt --no-dev > "$temp_requirements"

        if ! diff -q "$temp_requirements" requirements.txt >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Production requirements are out of sync. Run '$0 sync' to update.${NC}"
        else
            echo -e "${GREEN}✓ Production requirements are up to date${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No lockfile or requirements found. Run '$0 sync' to generate.${NC}"
    fi
}

# Main script logic
cd "$PACKAGE_ROOT"

# Check if pyproject.toml exists
if [[ ! -f "pyproject.toml" ]]; then
    echo -e "${RED}❌ Error: pyproject.toml not found. Please run this script from the hyprchrp repository.${NC}"
    exit 1
fi

# Parse command line arguments
case "${1:-}" in
    "add")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ Error: Package name required${NC}"
            show_usage
            exit 1
        fi
        add_dependency "$2" "false"
        ;;
    "add-dev")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ Error: Package name required${NC}"
            show_usage
            exit 1
        fi
        add_dependency "$2" "true"
        ;;
    "remove")
        if [[ -z "${2:-}" ]]; then
            echo -e "${RED}❌ Error: Package name required${NC}"
            show_usage
            exit 1
        fi
        remove_dependency "$2"
        ;;
    "update")
        update_dependencies "${2:-}"
        ;;
    "sync")
        sync_production
        ;;
    "tree")
        show_tree
        ;;
    "check")
        check_dependencies
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        echo -e "${RED}❌ Error: Command required${NC}"
        show_usage
        exit 1
        ;;
    *)
        echo -e "${RED}❌ Error: Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac