# Prism Analytics

A powerful ESP and analytics GUI for Roblox games with customizable features.

## Features

- **Player ESP**: Highlight players with customizable boxes
- **Name ESP**: Display player names above characters
- **Health ESP**: Show health bars and health values
- **Chams**: Highlight players through walls
- **Team Color Support**: Differentiate between teammates and enemies
- **Customizable UI**: Dark-themed interface with multiple tabs

## Installation

### Method 1: One-line Loader (Recommended)

Copy and paste this single line into your executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Amhim123hd/PRismWorld/main/prism_loader.lua"))()
```

### Method 2: Manual Installation

If the loader doesn't work, you can manually load each component:

```lua
-- Load ESP module
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Amhim123hd/PRismWorld/main/prism_esp.lua"))()

-- Load and initialize UI
loadstring(game:HttpGet("https://raw.githubusercontent.com/Amhim123hd/PRismWorld/main/ui.lua"))()
```

## Usage

1. Run the script using one of the installation methods above
2. Use the right-shift key to toggle the UI visibility
3. Navigate through the tabs to access different features:
   - **Players**: View and select players in the game
   - **Visuals**: Toggle ESP features like boxes, names, and health
   - **Aimbot**: Configure aimbot settings (if available)

## Compatibility

Prism Analytics is designed to work with most popular Roblox executors including:
- Synapse X
- Script-Ware
- KRNL
- Fluxus
- And many others

The ESP system uses Roblox Instances instead of the Drawing library for maximum compatibility.

## Credits

- Created by [Your Name]
- Special thanks to the Roblox scripting community

## License

This project is for educational purposes only. Use at your own risk.
