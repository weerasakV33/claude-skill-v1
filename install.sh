#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "claude-engineering-skills installer"
echo "====================================="
echo ""

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLAUDE_HOME="$HOME/.claude"
SKILLS_TARGET="$CLAUDE_HOME/skills"
CLAUDE_MD_TARGET="$CLAUDE_HOME/CLAUDE.md"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$CLAUDE_HOME/.backups/$TIMESTAMP"

# Create .claude if missing
if [ ! -d "$CLAUDE_HOME" ]; then
    mkdir -p "$CLAUDE_HOME"
    echo "Created $CLAUDE_HOME"
fi

# Backup existing
HAS_BACKUP=false
if [ -f "$CLAUDE_MD_TARGET" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$CLAUDE_MD_TARGET" "$BACKUP_DIR/CLAUDE.md"
    HAS_BACKUP=true
    echo "Backed up existing CLAUDE.md"
fi

if [ -d "$SKILLS_TARGET" ]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$SKILLS_TARGET" "$BACKUP_DIR/skills"
    HAS_BACKUP=true
    echo "Backed up existing skills/"
fi

if [ "$HAS_BACKUP" = true ]; then
    echo "Backups saved to: $BACKUP_DIR"
    echo ""
fi

# Install CLAUDE.md
CLAUDE_MD_SOURCE="$REPO_ROOT/CLAUDE.md"
if [ ! -f "$CLAUDE_MD_SOURCE" ]; then
    echo "ERROR: CLAUDE.md not found at $CLAUDE_MD_SOURCE"
    exit 1
fi
cp "$CLAUDE_MD_SOURCE" "$CLAUDE_MD_TARGET"
echo "Installed CLAUDE.md"

# Remove old skills folder if exists (so removed skills are cleaned up)
if [ -d "$SKILLS_TARGET" ]; then
    rm -rf "$SKILLS_TARGET"
fi
mkdir -p "$SKILLS_TARGET"

# Install skills
SKILLS_SOURCE="$REPO_ROOT/skills"
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo "ERROR: skills/ folder not found at $SKILLS_SOURCE"
    exit 1
fi

SKILL_COUNT=0
for skill_dir in "$SKILLS_SOURCE"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    if [ -f "$skill_file" ]; then
        dest_dir="$SKILLS_TARGET/$skill_name"
        mkdir -p "$dest_dir"
        cp "$skill_file" "$dest_dir/SKILL.md"
        echo "Installed skill: $skill_name"
        SKILL_COUNT=$((SKILL_COUNT + 1))
    fi
done

echo ""
echo "Done. Installed CLAUDE.md and $SKILL_COUNT skills."
echo ""
echo "Per-project memory at $CLAUDE_HOME/projects was not touched."
echo ""
echo "Next steps:"
echo "  1. Close all existing Claude Code terminals"
echo "  2. Open a new terminal"
echo "  3. Install MCP servers (see README.md)"
echo "  4. Run: claude"
echo ""
