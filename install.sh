#!/bin/bash
# Install or update Usage Limits in the local Plasma session.
set -euo pipefail

WIDGET_ID="com.crazytweeks.ai-limits"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

chmod +x "$SCRIPT_DIR/contents/scripts/collect_usage.py"

if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$WIDGET_ID"; then
    echo "Updating existing installation..."
    kpackagetool6 -t Plasma/Applet -u "$SCRIPT_DIR"
else
    echo "Installing widget..."
    kpackagetool6 -t Plasma/Applet -i "$SCRIPT_DIR"
fi

# Terminal command: ai-limits -> the installed collector, so widget updates
# also update the CLI.
INSTALLED="$HOME/.local/share/plasma/plasmoids/$WIDGET_ID/contents/scripts/collect_usage.py"
chmod +x "$INSTALLED"
mkdir -p "$HOME/.local/bin"
ln -sf "$INSTALLED" "$HOME/.local/bin/ai-limits"
echo "Installed command: $HOME/.local/bin/ai-limits"

# Claude Code skill, if Claude Code is set up for this user.
if [ -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude/skills"
    ln -sfn "$SCRIPT_DIR/skills/ai-limits" "$HOME/.claude/skills/ai-limits"
    echo "Installed Claude Code skill: $HOME/.claude/skills/ai-limits/SKILL.md"
fi

echo "Done. Test with: ai-limits, or plasmawindowed $WIDGET_ID"
