# Changelog

All notable changes to Fimbulwinter Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.2] - 2026-08-03

### Added
- korCaptain-NullReferenceFix 1.0.6 -- three independent Harmony patches that
  clean up recurring `NullReferenceException` log-spam/crash bugs instead of
  just catching and ignoring them: a vanilla `ZNetScene.RemoveObjects` engine
  bug, a stale-container bug in AzuCraftyBoxes (already installed in this
  pack -- confirmed via decompiled strings that the patch specifically
  checks for AzuCraftyBoxes's plugin GUID and only activates if present), and
  an `EnemyHud` mod-conflict bug (relevant if a player runs faction/HUD mods
  like EpicMMOSystem alongside this pack). No config, no keybinds -- verified
  by decompiling the DLL, zero `ConfigEntry`/`Bind` calls found. Install on
  server and all clients per the mod's own guidance (local per-instance
  state, not network-synced).
  Investigated VitByr-VBNetTweaks as a possible companion/replacement for
  NetworkTweaks per user request -- **not added**. Its own README lists
  `Searica.Valheim.NetworkTweaks` (our installed NetworkTweaks's exact
  plugin GUID) as a hard incompatibility, both patch the same vanilla ZDO
  send path. Also carries Thunderstore's "AI Generated" content tag and has
  1.5K downloads against NetworkTweaks's 26K/stable-since-2025 track record
  -- not a trade worth making for network-critical code.

### Changed
- AzuCraftyBoxes bumped 1.8.14 -> 1.8.15 (fixes an issue when destroying a
  fireplace; no config schema change). `Container Range` 20 -> 30 to
  compensate for the AutomaticFuel change below.
- AzuAutoStore: `Fallback Range` 15 -> 20. Also bumped the real functional
  range -- confirmed via source/yaml review that the shipped
  `Azumatt.AzuAutoStore.yml` pins every vanilla chest tier
  (`piece_chest`, `piece_chest_wood`, `piece_chest_private`,
  `piece_chest_blackmetal`) to an explicit per-container `range: 10` that
  overrides the config's fallback value entirely, so the config-only change
  would have been silently inert. All four bumped to `range: 20`.
- AutomaticFuel: disabled auto-refuel for everything in the `[Fireplace]`
  section -- `RefuelStandingTorches`, `RefuelWallTorches`, `RefuelFirePits`,
  `RefuelBraziers`, `RefuelHearth`, `RefuelHotTub` all off (were on). At
  user request: base-interior torches/hearth/hot tub were silently draining
  wood and resin from nearby chests. Confirmed via source that each toggle
  gates its structure type independently and fully short-circuits before
  any fuel-pulling logic runs, so this has zero effect on the separate
  `[Smelters]` section -- auto-smelting ore/coal and kiln/blast furnace
  behavior is untouched, exactly as wanted. The wider AzuCraftyBoxes/
  AzuAutoStore ranges above compensate for the loss of auto-refuel.
- ShieldBash `BashKey` Mouse2 -> Mouse3 (a side mouse button, not the
  scroll-wheel click) at user request. No conflicts: grepped every shipped
  config for `Mouse3` and found zero existing binds anywhere in the pack.

## [1.4.1] - 2026-08-02

### Added
- VentureValheim-Venture_Floating_Items 0.3.3 -- `FloatEverything = true`, so
  every dropped item floats instead of sinking, ore and metal bars included
  (at user request; overrides this mod's own safer default of only floating
  trophies/meat/hides/treasure/craftable-gear plus `SerpentScale`/
  `BonemawSerpentTooth`). `SinkingItems = BronzeNails, IronNails` still
  applies -- per the mod's own source, the sinking-list check runs before
  the `FloatEverything` check, so those two items are the sole exception
  and still sink. Uses Jotunn's built-in ConfigSync (all settings are
  admin-only/server-controlled), so this is genuinely server-enforced
  without needing a ConditionalConfigSync integration -- install on both
  server and clients.

### Fixed
- AAA_Crafting: all four crafting-menu keybinds (`Incremental Modifier`,
  `Max Craft Modifier`, `Show Minus Button`, `Toggle RecipeUI`) had been set
  to `None` instead of their real defaults, silently breaking Shift+scroll
  (increment craft amount by 5) and Ctrl+scroll (jump to max craftable) over
  the amount input box -- the actual cause of "shift-craft only crafts one."
  Restored to `LeftShift`, `LeftControl`, `LeftControl`, and
  `LeftShift + PageUp` respectively; all four only fire while the crafting
  menu is open, same context-scoped pattern already used elsewhere in this
  pack.

### Changed
- AAA_Crafting: `Vanilla-Like` off (was on) and `Grid Size` set to Medium --
  unlocks the mod's newer enhanced recipe grid instead of the classic vanilla
  view. `Favorting System` on (was off) with its `F` keybind restored
  (crafting-menu-only context, doesn't touch Forsaken Power).
- AzuExtendedPlayerInventory bumped 2.4.1 -> 2.4.2 (stacking fix with
  backpacks, tombstone patch). `Use Legacy Layout` off (was on) -- the pack
  had been opted into the pre-2.0 layout the whole time despite shipping the
  post-2.0 mod version. `Show Vanity Button` and `Show Loadout Button` both
  on (were off) -- pure cosmetic/equipment-set QoL from the 2.0 overhaul,
  zero balance impact.

## [1.4.0] - 2026-07-26

### Added
- Crystal-DigDeeper 1.1.7 -- raises the terrain dig/raise limit from vanilla's
  8m to 40m of depth and 16m of height. Client-only by the mod's
  own design -- it has no ConditionalConfigSync/ServerSync integration, so it
  cannot be enforced by the server. Installed on every client via this pack's
  shared config, which keeps everyone's value consistent through profile
  distribution rather than live server sync; a player who hand-edits their
  local config could desync terrain shape from others, same risk as with any
  unsynced client-only mod.

## [1.3.1] - 2026-07-26

### Changed
- shudnal-ConfigurationManager 1.1.15 → 1.1.16 — uses ConditionalConfigSync's
  effective administrator state when deciding whether server-provided hidden
  settings apply (avoids stale vanilla `AdminList` state). Requires
  ConditionalConfigSync 1.0.4+ (bumped alongside it below).
- shudnal-ConditionalConfigSync 1.0.3 → 1.0.4 — internal handshake/protocol
  reliability fixes. No config or gameplay-visible change; required as both
  ConfigurationManager 1.1.16's and Seasons 1.8.2's dependency floor.
- shudnal-Seasons 1.8.1 → 1.8.2 — Expand World Data compatibility fixes
  (biome environment/weather reload lifecycle). No config schema change.

## [1.3.0] - 2026-07-21

### Added
- Azumatt-ChangelogEditor 1.0.9 -- hides the main-menu changelog
  (`Should Show Changelog = Off`)
- Mexanik-ShieldBash 1.5.5 -- active shield bash attack. `BashKey` moved off
  its default `F` (collides with vanilla Forsaken Power) to `Mouse2`

### Changed
- QuickConnect UI tuned: `ButtonFontSize`/`LabelFontSize` 0→16,
  `WindowWidth` 250→384, `WindowHeight` 50→72, `WindowPosX`/`WindowPosY`
  20→50 (`CustomConnectionError` and `CustomDelimiter` already matched
  the desired defaults)
- server_devcommands: `Automatic devcommands = false` (was `true`) --
  devcommands mode no longer auto-enables for admins on join; must be
  explicitly activated
- MyLittleUI: `Show slots space taken = true`
- AutomaticFuel, at user request to widen coverage and fix disabled
  defaults from an earlier, forgotten tuning pass:
  - `FireplaceRange`, `DropRange`, `SmelterOreRange`, `SmelterFuelRange`:
    5 → 15 (the latter three restore the mod's own shipped default; all
    four are now consistent)
  - `RefuelStandingTorches`, `RefuelBraziers`, `RefuelHotTub`,
    `RefuelWallTorches`, `RefuelFirePits`, `RefuelHearth`: false → true
    (restores mod defaults -- every light/heat source now auto-refuels)
  - `Use Dropped Items for Fuel`: false → true (restores mod default)
  - `AllowStackSmelters`: false → true -- researched as the "best
    configuration" ask for Smelters/Kilns: this removes the vanilla
    smoke/smoke-blocked placement check so smelters/kilns can be built
    tight together, a standard QoL choice for this category of pack.
    `Turn Off Windmills/SpinningWheel/Kiln` were already `false` (meaning
    NOT turned off -- already enabled, no change needed) and
    `RestrictKilnOutput` stays `false` (unrestricted output is the more
    permissive state already, consistent with "auto-refuel everything")
- PlantEasily: `KeyboardModifierKey` (grid-resize modifier) moved from its
  default `RightControl` to `LeftAlt` -- Right Control is frequently
  missing or unreliable on laptop keyboards, which is almost certainly why
  it "didn't work"; Left Alt is universally present and doesn't collide
  with anything else in the pack
- AzuCraftyBoxes: `Prevent Pulling Logic` moved from `Alt + O` to
  `Alt + Slash` -- the bare `O` admin bind (`debugmode`+`nocost`+`god` in
  binds.yaml) fires regardless of what modifier is also held, so any admin
  using this ordinary client mod would accidentally toggle god mode/no-cost
  building/debug mode on themselves. Found via a keybind audit prompted by
  the same bug already caught and fixed in Fimbulwinter
- AzuExtendedPlayerInventory: quick slot 5 moved from `Alt + B` to
  `Alt + 3` -- collided with Extra Snap Points Made Easy's Manual+ snap
  toggle (`B`), found in the same audit pass

### Tooling
- `scripts/deploy.sh full` now calls `disable_auto_update()` before staging,
  which sets the egg's `AUTO_UPDATE_MODS` startup variable to `0` via the
  Pelican Client API. Fixes the recurring edge case where testing a full
  deploy on the server got reverted: the post-deploy restart's boot-time
  `server-autoupdate.sh` would re-sync to the latest *published*
  Thunderstore pack if `AUTO_UPDATE_MODS=1`, clobbering the unpublished
  local state just pushed for testing. The existing `local-*`
  manifest-marker skip (2026-07-18) was meant to prevent this but isn't
  relied on anymore -- the variable is switched off outright now.
  **Deploy.sh does not re-enable it automatically** -- flip
  `AUTO_UPDATE_MODS` back to `1` yourself once testing is done and you're
  ready to publish.

## [1.2.0] - 2026-07-19

### Added
- shudnal-LongshipUpgrades 1.0.17 -- removable mast (with hanging lantern,
  rest tent, and Wisp torch mounts), hull HP + fire/Ashlands-ocean-protection
  upgrades, 2-step storage expansion, cartography table map-data exchange
  between players, and cosmetic head/sail/shield/tent style switching.
  Requires the mod on server and every client (mod-specific RPCs; mismatched
  peers are rejected on connect).
  Tuned off the Vanilla+ line: `Turrets - Enable upgrades = false` (the
  auto-firing ballista turret is a new combat mechanic vanilla doesn't have)
  and `Item stand - Forsaken power enabled = false` (stops the trophy stand
  from granting a second, simultaneously-usable Forsaken power alongside
  your own -- preserves vanilla's one-power-at-a-time tradeoff; the trophy
  still mounts as a cosmetic figurehead). `Only creator can upgrade ship`
  and `Only creator can change trophy` set to false so any player can help
  upgrade a shared longship, matching the pack's cooperative-building
  philosophy (MultiUserChest, Groups).

### Fixed
- Server devcommands admin bind on F9 was silently broken -- half of it
  (`/creative`) called a command that does not exist in Server devcommands
  1.108.0 (verified against the shipped plugin binary), almost certainly a
  stale leftover from the original 111-mod Fimbulwinter pack. The bundle now
  toggles `debugmode` + `nocost` + `god` together on `O` (moved off `F9` --
  in testing, F9 triggered a Steam Input controller-layout switch, a known
  conflict category since F9-F12 are common defaults for Steam Input layout
  hotkeys, NVIDIA overlay, and keyboard macro software); a new admin-only
  bind on `K` toggles `fly` separately, since flight wasn't part of the old
  bundle at all.

## [1.1.1] - 2026-07-18

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
