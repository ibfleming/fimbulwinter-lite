[![Build Status](https://github.com/ibfleming/fimbulwinter-lite/actions/workflows/publish.yml/badge.svg)](https://github.com/ibfleming/fimbulwinter-lite/actions/workflows/publish.yml)

# Fimbulwinter Lite - A Vanilla+ Valheim Modpack

**Valheim, but smoother. No new content tiers, no overhauls -- just streamlined, polished vanilla.**

Fimbulwinter Lite is a curated, lightweight modpack of **53 mods** focused on quality-of-life, UI polish, multiplayer fixes, and subtle enhancements. Vanilla progression, balance, difficulty, and the spirit of the game are untouched. Every mod is actively maintained and verified against the current Valheim version.

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

### Inventory & Crafting (10 mods)
- **AzuExtendedPlayerInventory** -- Dedicated equipment and quick slots
- **AzuCraftyBoxes** -- Craft using materials from nearby containers
- **AzuAutoStore** -- Auto-deposit items into nearby containers
- **AzuContainerSizes** -- Larger chest capacities
- **AAA Crafting** -- Improved crafting UI with bulk crafting and upgrades
- **Recycle N Reclaim** -- Recycle items back into materials
- **Quick Stack Store Sort Trash Restock** -- One-key chest stacking, sorting, and trash
- **MultiUserChest** -- Multiple players can use one chest simultaneously
- **ComfyAutoRepair** -- Opening a crafting station repairs everything it can repair
- **AutomaticFuel** -- Smelters, kilns, windmills and spinning wheels feed from nearby chests

### UI & HUD (4 mods)
- **MyLittleUI** -- Lightweight UI upgrades: timers, stats, chest contents, weather
- **VNEI** -- In-game item and recipe browser
- **HUDCompass** -- Compass bar with map pins
- **AzuHoverStats** -- Detailed hover tooltips

### Building (6 mods)
- **Gizmo** -- Precise build-piece rotation on all axes
- **Extra Snap Points Made Easy** -- More snap points on every piece
- **AzuAreaRepair** -- Repair all nearby build pieces with one hammer hit
- **MissingPieces** -- Vanilla-styled build pieces that should have existed
- **AdvancedTerrainModifiers** -- Precision terraforming with square/circle modes and undo
- **NoRainDamage** -- Buildings no longer take weather damage

### Farming (3 mods)
- **PlantEverything** -- Plant every gatherable resource and tree
- **PlantEasily** -- Grid-aligned planting and mass harvesting
- **MassFarming** -- Bulk plant and pick with a modifier key

### Travel & World QoL (6 mods)
- **TeleportEverything** -- Portal everything, with a 10% ore transport tax
- **SpeedyPaths** -- Move faster on paths, roads, and cleared ground
- **WieldEquipmentWhileSwimming** -- Keep gear in hand while swimming
- **TargetPortal** -- Step into a portal, pick any other portal on the map
- **StumpsAreOneHp** -- Tree stumps fall in a single hit
- **LongshipUpgrades** -- Removable mast with lantern/tent/Wisp torch, hull HP and Ashlands-ocean protection, bigger storage, cartography table map sharing, and cosmetic ship styling

### Combat & Archery (2 mods)
- **ProjectileTweaks** -- Cleaner archery feel: arrows launch from where you aim, bow/crossbow zoom, draw cancel, ammo counter -- projectile physics stay vanilla
- **Headshots** -- Most organic creatures gain a head weakspot; precise shots with pierce damage are rewarded

### Fixes & Performance (5 mods)
- **AzuMiscPatches** -- Collection of small vanilla fixes and tweaks
- **LocalizationCache** -- Dramatically faster load times
- **TimeoutLimit** -- Fixes join timeouts on modded servers
- **NetworkTweaks** -- Improved network throughput
- **TrueInstantLootDrop** -- Loot drops instantly on kill

### Multiplayer & Server (7 mods)
- **ServerCharacters** -- Server-side character saves (anti-dupe, anti-cheat)
- **SleepSkip** -- Majority-rules night skipping: enough players in bed starts a vote, popup for the rest, AFK players count as abstaining
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

## Keyboard Shortcuts

All mod keybinds have been audited against Valheim's default bindings — nothing shadows a vanilla control. Modifier-based binds only act in their context (build mode, planting, menus) and don't interfere with the base action.

| Key | Mod | Action | Context |
|-----|-----|--------|---------|
| `Alt + Z / X / C` | AzuExtendedPlayerInventory | Use quick slot 1 / 2 / 3 | Anywhere |
| `I` | AdventureBackpacks | Open equipped backpack | Anywhere |
| `L` | AdventureBackpacks | Toggle Wisplight effect | Anywhere |
| `Alt + H` | VNEI | Open item/recipe browser | Anywhere |
| `R` | VNEI | View recipe of hovered item | Menus only (vanilla sheath unaffected) |
| `Left/Right Arrow` | VNEI | Recipe history back / forward | VNEI window |
| `Ctrl + Z` | Recycle N Reclaim | Undo last recycle | Inventory |
| `Delete` | Quick Stack Store | Trash hovered item | Inventory |
| `Shift` (hold) | AzuCraftyBoxes | Craft max / fill all | Crafting menu |
| `Shift` (hold) | Gizmo | Rotate build piece on X axis | Build mode (hammer only -- terrain tools stay vanilla) |
| `Alt` (hold) | Gizmo | Rotate build piece on Z axis | Build mode (hammer only -- terrain tools stay vanilla) |
| `G` | Gizmo | Reset selected-axis rotation | Build mode (moved off `V` = vanilla voice chat) |
| `T` | Gizmo | Reset ALL axis rotations | Build mode (disabled by default in the mod; enabled in this pack) |
| `P` | Gizmo | Copy rotation from targeted piece | Build mode |
| `B` | Extra Snap Points | Toggle Manual+ snap mode | Build mode (moved off `Alt` -- collided with Gizmo/terrain tools) |
| `CapsLock` | Extra Snap Points | Toggle manual closest-snap mode | Build mode |
| `Q` / `E` | Extra Snap Points | Cycle snap point on placing / targeted piece | Manual snap modes only (vanilla autorun/interact unaffected outside them) |
| `F11` | Extra Snap Points | Toggle grid snapping | Build mode (moved off `F3` = config manager) |
| `F4` | Extra Snap Points | Cycle grid snap precision | Grid snap mode |
| `Shift` (hold) | MassFarming | Mass plant / mass pick | Cultivator / interact |
| `F8` | PlantEasily | Toggle grid planting | Cultivator |
| `F10` | PlantEasily | Toggle grid snapping | Cultivator |
| `F6` | PlantEasily | Toggle auto-replant | Anywhere |
| `RCtrl + Arrows` | PlantEasily | Resize planting grid | Cultivator |
| `Shift` (hold) | PlantEasily | Harvest whole grid | Interact |
| `Alt + click` | Groups | Ping map for your group | Map |
| `F3` | ConfigurationManager | Open in-game mod settings | Anywhere |
| `F7` | AutomaticFuel | Toggle auto-fueling on/off | Anywhere |
| `Alt + scroll` | AdvancedTerrainModifiers | Adjust tool radius | Hoe/cultivator/shovel |
| `Ctrl + scroll` | AdvancedTerrainModifiers | Adjust tool hardness | Hoe/cultivator/shovel |
| `Shift` (hold) + use portal | TargetPortal | Use vanilla tag UI instead | At portal |
| `P` | TargetPortal | Toggle portal icons | Map open |
| `Right Mouse` (hold) | ProjectileTweaks | Zoom while drawing bow/crossbow | Bow drawn |
| `E` | ProjectileTweaks | Cancel bow draw | While drawing only (vanilla interact otherwise) |
| `O` | Server devcommands | Toggle debug mode + no-cost building + god mode | Admin only -- all three toggle together (moved off `F9`; F-keys risk collisions with Steam Input controller-layout hotkeys, NVIDIA overlay, and keyboard macro software) |
| `K` | Server devcommands | Toggle fly mode | Admin only -- separate from the O bundle |
| `Ctrl + Right-click` | Server devcommands | Teleport to map location | Admin only, map open |

Rebind anything in-game: press `F3` → find the mod → change the key (stored in that mod's config file).

## Installation

**Client:** Install via [r2modman](https://thunderstore.io/c/valheim/p/ebkr/r2modman/) or the Thunderstore App -- search for `Fimbulwinter Lite` by `ibfleming`.

**Alternative (profile import):** Each [GitHub release](https://github.com/ibfleming/fimbulwinter-lite/releases) ships a ready-made `.r2z` profile with all mods at pinned versions plus the tuned configs. In r2modman: Profiles -> Import / Update -> From file.

**Server:** Install all mods except client-only UI/visual mods. A Pelican/Pterodactyl server egg is provided in the [GitHub repo](https://github.com/ibfleming/fimbulwinter-lite) (`server/valheim-fimbulwinter-lite-egg.yaml`) that automates the full dedicated server install: SteamCMD, BepInEx, all server-side mods, and modpack configs.

## Links

- **GitHub:** [github.com/ibfleming/fimbulwinter-lite](https://github.com/ibfleming/fimbulwinter-lite)
- **Issues & suggestions:** [GitHub Issues](https://github.com/ibfleming/fimbulwinter-lite/issues)
- **Changelog:** [CHANGELOG.md](https://github.com/ibfleming/fimbulwinter-lite/blob/main/CHANGELOG.md)
