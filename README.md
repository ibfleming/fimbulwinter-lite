[![Build Status](https://github.com/ibfleming/fimbulwinter-lite/actions/workflows/publish.yml/badge.svg)](https://github.com/ibfleming/fimbulwinter-lite/actions/workflows/publish.yml)

# Fimbulwinter Lite - A Vanilla+ Valheim Modpack

**Valheim, but smoother. No new content tiers, no overhauls -- just streamlined, polished vanilla.**

Fimbulwinter Lite is a curated, lightweight modpack of **43 mods** focused on quality-of-life, UI polish, multiplayer fixes, and subtle enhancements. Vanilla progression, balance, difficulty, and the spirit of the game are untouched. Every mod is actively maintained and verified against the current Valheim version.

## Design Principles

- **Preserve the Spirit of Valheim** -- No teleport-cheese (ore transport carries a 10% tax), no game-breaking shortcuts. Progression still requires biome exploration and earned power.
- **Vanilla+ Over Overhaul** -- Enhance what exists instead of replacing it. No new biomes, gear tiers, magic systems, or creature packs.
- **Multiplayer-First** -- Every mod works on dedicated servers, with server-enforced config sync.
- **Actively Maintained** -- Every mod verified current against Thunderstore; no deprecated or abandoned mods.

## What's Included

### Core & Frameworks (6 mods)
- **BepInExPack_Valheim** -- Mod loader
- **Jotunn** -- Modding framework
- **JsonDotNET / YamlDotNet** -- Shared libraries
- **ConfigurationManager** (shudnal) -- In-game config editing (F1)
- **ConditionalConfigSync** -- Server-enforced config ownership and sync policies

### Inventory & Crafting (8 mods)
- **AzuExtendedPlayerInventory** -- Dedicated equipment and quick slots
- **AzuCraftyBoxes** -- Craft using materials from nearby containers
- **AzuAutoStore** -- Auto-deposit items into nearby containers
- **AzuContainerSizes** -- Larger chest capacities
- **AAA Crafting** -- Improved crafting UI with bulk crafting and upgrades
- **Recycle N Reclaim** -- Recycle items back into materials
- **Quick Stack Store Sort Trash Restock** -- One-key chest stacking, sorting, and trash
- **MultiUserChest** -- Multiple players can use one chest simultaneously

### UI & HUD (4 mods)
- **MyLittleUI** -- Lightweight UI upgrades: timers, stats, chest contents, weather
- **VNEI** -- In-game item and recipe browser
- **HUDCompass** -- Compass bar with map pins
- **AzuHoverStats** -- Detailed hover tooltips

### Building (4 mods)
- **Gizmo** -- Precise build-piece rotation on all axes
- **Extra Snap Points Made Easy** -- More snap points on every piece
- **AzuAreaRepair** -- Repair all nearby build pieces with one hammer hit
- **MissingPieces** -- Vanilla-styled build pieces that should have existed

### Farming (3 mods)
- **PlantEverything** -- Plant every gatherable resource and tree
- **PlantEasily** -- Grid-aligned planting and mass harvesting
- **MassFarming** -- Bulk plant and pick with a modifier key

### Travel & World QoL (3 mods)
- **TeleportEverything** -- Portal everything, with a 10% ore transport tax
- **SpeedyPaths** -- Move faster on paths, roads, and cleared ground
- **WieldEquipmentWhileSwimming** -- Keep gear in hand while swimming

### Fixes & Performance (5 mods)
- **AzuMiscPatches** -- Collection of small vanilla fixes and tweaks
- **LocalizationCache** -- Dramatically faster load times
- **TimeoutLimit** -- Fixes join timeouts on modded servers
- **NetworkTweaks** -- Improved network throughput
- **TrueInstantLootDrop** -- Loot drops instantly on kill

### Multiplayer & Server (6 mods)
- **ServerCharacters** -- Server-side character saves (anti-dupe, anti-cheat)
- **Server devcommands** -- Better admin commands and permissions
- **Upgrade World** -- Regenerate world locations after game updates
- **QuickConnect** -- One-click server join
- **Venture Logout Tweaks** -- Safe logout handling
- **ShutUp** -- Silences console log spam

### Progression & Content (4 mods)
- **SmartSkills** -- 75% skill recovery after death; death matters but isn't crushing
- **AdventureBackpacks** -- Progression-gated craftable backpacks
- **Groups** -- Party system with shared map pings and chat
- **Seasons** -- Four rotating seasons with visual and gameplay variety

## Installation

**Client:** Install via [r2modman](https://thunderstore.io/c/valheim/p/ebkr/r2modman/) or the Thunderstore App -- search for `FimbulwinterLite` by `ibfleming`.

**Server:** Install all mods except client-only UI/visual mods. A Pelican/Pterodactyl server egg is provided in the [GitHub repo](https://github.com/ibfleming/fimbulwinter-lite) (`server/valheim-fimbulwinter-lite-egg.yaml`) that automates the full dedicated server install: SteamCMD, BepInEx, all server-side mods, and modpack configs.

## Links

- **GitHub:** [github.com/ibfleming/fimbulwinter-lite](https://github.com/ibfleming/fimbulwinter-lite)
- **Issues & suggestions:** [GitHub Issues](https://github.com/ibfleming/fimbulwinter-lite/issues)
- **Changelog:** [CHANGELOG.md](https://github.com/ibfleming/fimbulwinter-lite/blob/main/CHANGELOG.md)
