# Changelog

All notable changes to Fimbulwinter Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - Unreleased

### Added
- Azumatt-SleepSkip 1.3.0 -- majority-rules night skipping: 2+ players in bed
  starts a vote, everyone else gets a popup, strict majority (51%) passes;
  AFK players abstain after 45s, players in combat auto-deny

### Changed
- Gizmo reset-ALL-rotations key enabled on T (disabled by default in the mod) --
  Gizmo's rotation state persists across tool swaps by design, so leftover
  X/Z rotations can surprise you; one press of T zeroes everything
- shudnal-ConfigurationManager updated from 1.1.14 to 1.1.15 (its own settings
  are now managed through ConditionalConfigSync; remains client-optional)
- ProjectileTweaks ammo counter restyled: icon still hidden, text size 21,
  centered, white, position (0, 0)

### Fixed
- Seasons `Control grass`, `Custom textures`, and the whole grass-tuning
  section are now client-controlled instead of server-enforced -- the prior
  blanket server-authoritative sync policy meant one server-side value forced
  grass off (or on) for every player with no way to override locally, and in
  testing a server-enforced `Control grass = false` was observed to clear
  grass entirely rather than just revert to vanilla. Season timing, weather,
  and stats remain server-authoritative so the world stays in sync; visual
  grass/texture toggles are now each player's own choice.

## [1.1.0] - 2026-07-15

### Added
- JoelOliMclean-NoRainDamage 1.2.4 -- buildings no longer take weather/rain
  damage (Structure_Tweaks was evaluated first but has no global weather
  toggle -- its wear system is per-object/visual)
- Smoothbrain-TargetPortal 1.2.3 -- step into any portal and pick your
  destination on the map; no more tag pairing (TeleportEverything's 10%
  ore tax still applies to what you carry)
- TastyChickenLegs-AutomaticFuel 1.4.8 -- smelters, kilns, windmills and
  spinning wheels auto-feed from nearby chests (torch/campfire/brazier fueling
  and ground pickup disabled; chest range 5m; toggle key F7)
- Searica-AdvancedTerrainModifiers 1.4.1 -- precision terraforming with
  square/circle modes and undo/redo
- coemt-StumpsAreOneHp 0.0.1 -- tree stumps fall in a single hit
- Searica-ProjectileTweaks 1.6.0 -- cleaner archery feel: launch-point fix so
  arrows go where the crosshair points, bow/crossbow zoom (hold right mouse
  while drawing), draw cancel (E), ammo count icon; all projectile physics
  multipliers kept at vanilla values
- Revel-Headshots 1.0.2 -- most organic creatures gain a head weakspot that
  rewards precise pierce-damage shots (arrows/bolts); frozen micro-mod,
  carried over from the original Fimbulwinter pack

### Changed
- Gizmo no longer applies to terrain-modifying tools (hoe/cultivator/shovel keep
  vanilla rotation) -- removes rotation-ring UI and Alt-key overlap with
  AdvancedTerrainModifiers scroll controls
- Extra Snap Points Made Easy keybinds rebound to remove collisions:
  Manual+ snap mode Alt -> B (Alt is held for Gizmo z-rotation and terrain-tool
  radius scrolling), grid snap F3 -> F11 (F3 opens the config manager);
  snap notifications moved from center-screen to top-left (snap-point cycling
  stays on Q/E -- active only inside manual snap modes)
- shudnal-ConfigurationManager updated from 1.1.13 to 1.1.14
- shudnal-ConditionalConfigSync updated from 1.0.1 to 1.0.2
- shudnal-Seasons updated from 1.8.0 to 1.8.1 (requires ConditionalConfigSync 1.0.2)

## [1.0.1] - 2026-07-14

### Added
- ComfyMods-ComfyAutoRepair 1.0.0 -- interacting with a crafting station
  auto-repairs all items that station can repair (client-side, vanilla rules
  preserved: station level and proximity still required)

## [1.0.0] - 2026-07-13

Initial release of **Fimbulwinter Lite** -- a complete Vanilla+ refactor of the original
Fimbulwinter modpack (`ibfleming/Fimbulwinter`, retired at v1.6.1). The pack was rebuilt
from 111 mods down to 43, removing all content overhauls (creatures, weapons, magic,
loot systems, difficulty scaling) in favor of a lightweight, maintainable QoL layer that
preserves vanilla progression and balance.

### Added
- **Core:** BepInExPack_Valheim 5.4.2333, Jotunn 2.29.2, JsonDotNET 13.0.4,
  YamlDotNet 16.3.1, ConfigurationManager 1.1.13, ConditionalConfigSync 1.0.1
- **Inventory & Crafting:** AzuExtendedPlayerInventory 2.4.1, AzuCraftyBoxes 1.8.14,
  AzuAutoStore 3.0.14, AzuContainerSizes 1.1.4, AAA_Crafting 2.1.6,
  Recycle_N_Reclaim 1.4.0, Quick_Stack_Store_Sort_Trash_Restock 1.4.13,
  MultiUserChest 0.6.1
- **UI & HUD:** MyLittleUI 1.2.15, VNEI 0.17.5, HUDCompass 1.1.9, AzuHoverStats 1.1.9
- **Building:** Gizmo 1.15.0, Extra_Snap_Points_Made_Easy 2.0.5, AzuAreaRepair 1.1.6,
  MissingPieces 2.2.3
- **Farming:** PlantEverything 1.20.0, PlantEasily 2.1.1, MassFarming 1.11.0
- **Travel & World:** TeleportEverything 2.9.1 (10% ore transport tax),
  SpeedyPaths 1.0.9, WieldEquipmentWhileSwimming 1.1.3
- **Fixes & Performance:** AzuMiscPatches 1.2.8, LocalizationCache 0.3.0,
  TimeoutLimit 0.2.0, NetworkTweaks 0.1.5, TrueInstantLootDrop 1.0.3
- **Multiplayer & Server:** ServerCharacters 1.4.16, Server_devcommands 1.108.0,
  Upgrade_World 1.80.0, QuickConnect 1.7.0, Venture_Logout_Tweaks 0.6.0, ShutUp 1.0.2
- **Progression & Content:** SmartSkills 1.0.2, AdventureBackpacks 1.9.13,
  Groups 1.2.10, Seasons 1.8.0

### Changed (from Fimbulwinter 1.6.1)
- Replaced BetterUI_ForeverMaintained with MyLittleUI (lighter, actively maintained)
- Replaced Seasonality + Willybach HD Seasonality with shudnal Seasons (one mod, no
  heavy texture pack, actively maintained)
- New mods over the old pack: ConditionalConfigSync, VNEI, Gizmo,
  Extra_Snap_Points_Made_Easy, AzuAreaRepair, AzuMiscPatches, MassFarming, Groups

### Removed (from Fimbulwinter 1.6.1)
- All content and overhaul mods (~75): EpicLoot + Therzie bridge,
  CreatureLevelAndLootControl, the Therzie suite (Warfare, Armory, Monstrum, Wizardry),
  the RtD suite, warpalicious locations, Bestiary, SeaAnimals, MushroomMonsters,
  Fee_Fi_Fo_Fum, EpicValheimsAdditions, Custom_Raids, Drop_That, Spawn_That,
  This_Goes_Here, DragoonCapes, OdinHorse, OdinShip, BetterArchery, ShieldBash,
  Headshots, TradersExtended, CircletExtended, GammaOfNightLights, Scenic,
  all Smoothbrain skill mods (Sailing, Mining, Farming, Foraging, Lumberjacking,
  Building, Blacksmithing, Evasion, Tenacity, DualWield, Resurrection), and more
- Deprecated mods: StartupHotfix, ItemDrawers
- Redundant mods: LeanNet (NetworkTweaks retained as the single network layer)
