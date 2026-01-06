#!/bin/bash

# 🖥 Claude Code Now & Codex Now - Quick Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/XinXin622/claude-code-now/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# GitHub repo
REPO="XinXin622/claude-code-now"

echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    🖥 Claude Code Now & Codex Now Installer       ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ Error: This installer only supports macOS${NC}"
    exit 1
fi

# Get latest release info
echo -e "${BLUE}📡 Fetching latest release...${NC}"
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Error: Could not fetch latest release${NC}"
    echo -e "${YELLOW}   Please check your internet connection or download manually from:${NC}"
    echo -e "${CYAN}   https://github.com/$REPO/releases${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Latest version: $VERSION${NC}"
echo ""

# Ask user which app(s) to install
echo -e "${YELLOW}Which app(s) would you like to install?${NC}"
echo "  1) Claude Code Now (for claude CLI)"
echo "  2) Codex Now (for codex CLI)"
echo "  3) Both"
echo ""
read -p "Enter choice [1-3, default: 3]: " CHOICE
CHOICE=${CHOICE:-3}

INSTALL_CLAUDE=false
INSTALL_CODEX=false

case $CHOICE in
    1) INSTALL_CLAUDE=true ;;
    2) INSTALL_CODEX=true ;;
    3) INSTALL_CLAUDE=true; INSTALL_CODEX=true ;;
    *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
esac

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Function to install an app
install_app() {
    local APP_NAME="$1"
    local ZIP_NAME="$2"
    
    echo ""
    echo -e "${BLUE}📥 Downloading $APP_NAME...${NC}"
    
    # Get download URL
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep "browser_download_url" | grep "$ZIP_NAME" | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/')
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}❌ Error: Could not find download URL for $ZIP_NAME${NC}"
        return 1
    fi
    
    # Download
    curl -fsSL -o "$ZIP_NAME" "$DOWNLOAD_URL"
    
    echo -e "${BLUE}📦 Extracting...${NC}"
    unzip -q "$ZIP_NAME"
    
    # Check if app already exists
    if [ -d "/Applications/$APP_NAME.app" ]; then
        echo -e "${YELLOW}⚠️  $APP_NAME.app already exists in Applications${NC}"
        read -p "   Overwrite? [y/N]: " OVERWRITE
        if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
            rm -rf "/Applications/$APP_NAME.app"
        else
            echo -e "${YELLOW}   Skipped $APP_NAME${NC}"
            return 0
        fi
    fi
    
    # Move to Applications
    echo -e "${BLUE}📁 Installing to /Applications...${NC}"
    mv "$APP_NAME.app" /Applications/
    
    echo -e "${GREEN}✅ $APP_NAME installed successfully!${NC}"
}

# Install selected apps
if [ "$INSTALL_CLAUDE" = true ]; then
    install_app "Claude Code Now" "Claude.Code.Now.${VERSION}.macOS.zip"
fi

if [ "$INSTALL_CODEX" = true ]; then
    install_app "Codex Now" "Codex.Now.${VERSION}.macOS.zip"
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              🎉 Installation Complete!            ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
if [ "$INSTALL_CLAUDE" = true ]; then
    echo "   • Open Finder, find Claude Code Now in Applications"
    echo "   • Drag it to your Dock for quick access"
fi
if [ "$INSTALL_CODEX" = true ]; then
    echo "   • Open Finder, find Codex Now in Applications"
    echo "   • Drag it to your Dock for quick access"
fi
echo ""
echo -e "${YELLOW}💡 Tip: 删除 ~/.config/claude-code-now/terminal 或${NC}"
echo -e "${YELLOW}       ~/.config/codex-now/terminal 可重置终端选择${NC}"
echo ""
