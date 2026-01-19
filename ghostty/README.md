# Ghostty Configuration

## Shortcut Setup

### Configure keyboard shortcut to toggle Ghostty

1. Open **Shortcuts.app**
2. Create a new shortcut (⌘N)
3. Add a "Run AppleScript" action
4. Copy the contents of `toggle_ghostty.applescript` and paste it into the script editor
5. Open the shortcut info panel
6. Enable quick action
7. Assign your preferred key combination
8. Close the info panel
9. Name the shortcut "Toggle Ghostty"

The shortcut will now:
- Launch Ghostty if it's not running
- Hide Ghostty if it's currently focused
- Show and focus Ghostty if it's hidden or in the background
