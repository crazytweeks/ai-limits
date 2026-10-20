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

echo "Done. Test with: plasmawindowed $WIDGET_ID"
