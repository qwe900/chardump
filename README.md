# chardump

A World of Warcraft addon for Wrath of the Lich King (3.3.5) that creates comprehensive character dumps, saving all relevant character data to SavedVariables for backup, analysis, or transfer purposes.

## Features

- **Complete Character Dump**: Captures extensive character information including:
  - Player stats and info
  - Spells and talents
  - Inventory and bank contents
  - Achievements and statistics
  - Reputation standings
  - Macros and keybindings
  - Action bars
  - Professions and skills
  - Quest completions
  - Currencies
  - Glyphs and mounts/pets

- **User-Friendly GUI**: Simple interface with progress bar and confirmation dialogs
- **Localization Support**: English (default) and German translations
- **Safe Data Handling**: Uses base64 encoding for secure storage
- **Status Commands**: Check dump status and saved data

## Installation

1. Download the addon files
2. Extract the `chardump` folder to your `World of Warcraft/Interface/AddOns/` directory
3. Restart World of Warcraft or reload your UI with `/reload`
4. The addon will be available via the `/chardump` command

## Usage

### Starting a Dump

- Type `/chardump` in chat to open the main GUI
- Click "Yes" to confirm and start the dump process
- The addon will systematically collect all character data
- Progress is shown in the GUI with a status bar

### Commands

- `/chardump` - Opens the GUI to start a new character dump
- `/chardump status` - Shows current dump status and saved data information
- `/chardump help` - Displays usage information

### Data Storage

- Dump data is saved to `WTF/Account/<Account>/<Realm>/<Character>/SavedVariables/chardump.lua`
- Data is stored in base64-encoded format for security
- Use `/reload` or log out to ensure the file is written to disk

## Localization

The addon supports both English and German languages. The language is automatically detected based on your WoW client locale.

## Requirements

- World of Warcraft: Wrath of the Lich King (3.3.5)
- Compatible with WotLK private servers

## Version

Current version: 1.0.0

## Author

Frost
## License

Free