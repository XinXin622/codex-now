#!/bin/bash

# 🖥 Claude Code Now - 即时启动，无需确认
# Shell script to launch Claude Code Now in current directory

# Detect and add nvm Node.js path dynamically
NVM_NODE_PATH=""
if [ -d "$HOME/.nvm" ]; then
    # Try to load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 2>/dev/null || true

    # Try to get current/default Node.js version
    if command -v nvm >/dev/null 2>&1; then
        # Get current node version or default version
        CURRENT_NODE_VERSION=$(nvm current 2>/dev/null | grep -v 'none' | head -1 || nvm alias default 2>/dev/null | grep -v 'default -> N/A' | head -1 || "")
        if [ -n "$CURRENT_NODE_VERSION" ] && [ "$CURRENT_NODE_VERSION" != "none" ] && [ "$CURRENT_NODE_VERSION" != "system" ]; then
            NVM_NODE_PATH="$HOME/.nvm/versions/node/$CURRENT_NODE_VERSION/bin"
        else
            # Fallback: find the latest installed version
            LATEST_NODE_VERSION=$(ls "$HOME/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1 || echo "")
            if [ -n "$LATEST_NODE_VERSION" ]; then
                NVM_NODE_PATH="$HOME/.nvm/versions/node/$LATEST_NODE_VERSION/bin"
            fi
        fi
    else
        # Fallback: find the latest installed version without nvm command
        LATEST_NODE_VERSION=$(ls "$HOME/.nvm/versions/node/" 2>/dev/null | sort -V | tail -1 || echo "")
        if [ -n "$LATEST_NODE_VERSION" ]; then
            NVM_NODE_PATH="$HOME/.nvm/versions/node/$LATEST_NODE_VERSION/bin"
        fi
    fi
fi

# 设置完整的PATH，包含更多可能的安装路径
if [ -n "$NVM_NODE_PATH" ]; then
    export PATH="$NVM_NODE_PATH:$HOME/.npm-global/bin:$HOME/.npm/bin:$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/local/share/npm/bin:$PATH"
else
    export PATH="$HOME/.npm-global/bin:$HOME/.npm/bin:$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/local/share/npm/bin:$PATH"
fi

# 保存上次目录的配置文件
LAST_DIR_FILE="$HOME/.claude-code-now-last-dir"

# 如果用户提供了参数，使用参数
if [ -n "$1" ]; then
    TARGET_DIR="$1"
# 否则尝试读取上次的目录
elif [ -f "$LAST_DIR_FILE" ]; then
    TARGET_DIR=$(cat "$LAST_DIR_FILE")
# 都没有则使用主目录
else
    TARGET_DIR="$HOME"
fi

# 检查目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目录 '$TARGET_DIR' 不存在"
    exit 1
fi

# 切换到目标目录并启动Claude Code Now
cd "$TARGET_DIR" || exit 1

echo "🖥 在目录 '$TARGET_DIR' 启动 Claude Code Now..."

# 启动Claude Code - 即时启动，无需确认
# 增强的路径检测逻辑，支持多种安装方式
CLAUDE_PATH=""

# Function to check if a path contains claude and is executable
check_claude_path() {
    if [ -f "$1" ] && [ -x "$1" ]; then
        CLAUDE_PATH="$1"
        return 0
    fi
    return 1
}

# Function to find all node versions in nvm
find_nvm_claude() {
    if [ -d "$HOME/.nvm/versions/node" ]; then
        # Find the latest node version's bin directory
        LATEST_NODE=$(ls -t "$HOME/.nvm/versions/node/" 2>/dev/null | head -1)
        if [ -n "$LATEST_NODE" ]; then
            check_claude_path "$HOME/.nvm/versions/node/$LATEST_NODE/bin/claude" && return 0
        fi
        # Also check all versions in case latest doesn't have it
        for node_version in "$HOME/.nvm/versions/node/"*; do
            if [ -d "$node_version" ]; then
                check_claude_path "$node_version/bin/claude" && return 0
            fi
        done
    fi
    return 1
}

# Function to dynamically detect package manager bin directories
detect_package_manager_bins() {
    # Try npm global prefix
    if command -v npm >/dev/null 2>&1; then
        NPM_PREFIX=$(npm config get prefix 2>/dev/null)
        if [ -n "$NPM_PREFIX" ] && [ -d "$NPM_PREFIX/bin" ]; then
            check_claude_path "$NPM_PREFIX/bin/claude" && return 0
        fi
    fi

    # Try yarn global bin
    if command -v yarn >/dev/null 2>&1; then
        YARN_BIN=$(yarn global bin 2>/dev/null)
        if [ -n "$YARN_BIN" ] && [ -d "$YARN_BIN" ]; then
            check_claude_path "$YARN_BIN/claude" && return 0
        fi
    fi

    # Try pnpm bin
    if command -v pnpm >/dev/null 2>&1; then
        PNPM_BIN=$(pnpm bin -g 2>/dev/null)
        if [ -n "$PNPM_BIN" ] && [ -d "$PNPM_BIN" ]; then
            check_claude_path "$PNPM_BIN/claude" && return 0
        fi
    fi

    return 1
}

# Priority 1: Check if claude is already in PATH
if command -v claude >/dev/null 2>&1; then
    CLAUDE_PATH=$(command -v claude)
fi

# Priority 2: If not found in PATH, try dynamic package manager detection
if [ -z "$CLAUDE_PATH" ]; then
    detect_package_manager_bins
fi

# Priority 3: Check nvm installations
if [ -z "$CLAUDE_PATH" ]; then
    find_nvm_claude
fi

# Priority 4: Check all known static paths (ordered by likelihood)
if [ -z "$CLAUDE_PATH" ]; then
    # Common user-local installations
    for path in "$HOME/.local/bin/claude" "$HOME/.npm-global/bin/claude" "$HOME/.npm/bin/claude" "$HOME/Library/pnpm/claude" "$HOME/.yarn/bin/claude" "/usr/local/bin/claude" "/opt/homebrew/bin/claude" "/usr/bin/claude" "$HOME/.cargo/bin/claude"
    do
        check_claude_path "$path" && break
    done
fi

# If still not found, provide helpful error message
if [ -z "$CLAUDE_PATH" ]; then
    echo "❌ 错误: Claude Code 未安装或不在 PATH 中"
    echo ""
    echo "🔍 已搜索以下位置："
    echo "   • 当前 PATH"
    echo "   • npm 全局安装目录"
    echo "   • yarn 全局安装目录"
    echo "   • pnpm 全局安装目录"
    echo "   • 所有 nvm Node.js 版本"
    echo "   • ~/.local/bin"
    echo "   • ~/.npm-global/bin"
    echo "   • ~/.npm/bin"
    echo "   • ~/.yarn/bin"
    echo "   • ~/Library/pnpm"
    echo "   • /usr/local/bin"
    echo "   • /opt/homebrew/bin"
    echo "   • /usr/bin"
    echo ""
    echo "💡 如何修复："
    echo "   1. 安装 Claude Code CLI:"
    echo "      npm install -g claude"
    echo ""
    echo "   2. 或检查是否已安装:"
    echo "      command -v claude"
    echo ""
    echo "   3. 或查看 npm 全局安装路径:"
    echo "      npm config get prefix"
    exit 1
fi

echo "✅ 找到 Claude Code: $CLAUDE_PATH"

# 保存当前目录，供下次使用
echo "$TARGET_DIR" > "$LAST_DIR_FILE"

"$CLAUDE_PATH" --permission-mode bypassPermissions