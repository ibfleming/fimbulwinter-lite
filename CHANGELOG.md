# Changelog

All notable changes to Fimbulwinter Lite will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - UNRELEASED - branch `lite-minimal`, local only, DO NOT PUBLISH

### Verified (2026-09-15, later still) -- first server boot with Jotunn + AdventureBackpacks
Deployed `f3ae3b0` and boot-verified: 17/17 plugins including `Jotunn 2.30.0`
and `Adventure Backpacks 2.0.4`, Jotunn's ModCompatibility/Synchronization/
Network/Localization managers all initialized clean, 0 exceptions -- the
server's first boot with Jotunn present on this branch.

Pulled every regenerated config off the live server and diffed against
`config/`, not just AdventureBackpacks:
- **`vapok.mods.adventurebackpacks.cfg` added, shipped for the first time.**
  All six backpack tiers (Satchel 5 -> Rugged 10 -> Bloodbag Wetpack 15 ->
  Arctic Sherpa 20 -> Lox Hide Knappsack 25 -> Explorers Wisppack 30 carry
  bonus) came back at the mod's own defaults -- and for every tier the old
  pre-1.0 pack also shipped, those defaults are **identical** to what ran
  for months there (same costs, same -15% speed tradeoff, same
  `Drops Enabled = false`). The two genuinely new keys from the 2.0.0
  rewrite (`Adjust Drop Count By Level`, `...by World Scaling`) both landed
  at `false`. Keybinds confirmed exactly as documented: `I` / `Y` / `L`.
  Nothing to tune.
- **`server_devcommands.cfg` gained a real key we missed at the 1.113.0 bump
  on 2026-09-12**: `Disable cheat tracking` (default `true`, "prevents
  commands from marking the character as having used cheats"). Added
  explicitly to `config/` now, at its default.
- Six other files showed a diff (`dev.crystal.deathpenalty.cfg`,
  `shudnal.ExtraSlots.cfg`, `ArgusMagnus.ServersideQoL.cfg`/`.AutoStore.cfg`/
  `.ContainerSizes.cfg`) -- all cosmetic. BepInEx rewrites its own
  auto-generated comment banner (plugin name + version) and description text
  on every save; actual key=value pairs were checked separately and are
  byte-identical. `DeathPenalty`'s custom prose comments in `config/` get
  overwritten by the mod's own boilerplate the moment it boots -- known,
  harmless, comments only.
- Confirmed client-only mods' config files (Gizmo, HUDCompass, MyLittleUI,
  ESPME, the ATM fork) exist on the server's filesystem too -- `deploy.sh`
  copies the whole flat `config/` tree verbatim regardless of which plugins
  are actually installed. Expected; those files are inert since the
  corresponding plugin DLLs are never installed server-side.

> Not a release. A ground-up rebuild for Valheim 1.0 with zero Azumatt mods and
> most QoL moved server-side. 25 packages, down from 58.

### Added (2026-09-15, later) -- Vapok-AdventureBackpacks, both sides -- Jotunn returns to the server
Researched at user request; asked explicitly before proceeding since this
reverses part of the original lite-minimal rebuild (see the `[2.0.0]`
"Removed" entry below: "Jotunn, and everything that needed it... The new
dependency graph has no Jotunn at all"). User chose to proceed and accept
Jotunn back on the server.

Not deprecated, actively maintained (updated as recently as 2026-09-15).
Confirmed 1.0-ready since its 2.0.0 rewrite ("Updated all Transpilers and
Harmony References... Fixed: Drop rates now properly account for World
Scaling and Level/Star creature ratings"); 2.0.1-2.0.4 are follow-up
mod-compatibility and duplication-guard fixes. Pinned at **2.0.4**.

Its own README is explicit: "Required on Both Client & Server... Built-in
version checking ensures game-state and inventory consistency" -- this is a
ModRequired content mod, not a QoL mod console/vanilla clients can skip.
`ValheimModding-Jotunn` (already pinned at 2.30.0 for the ATM fork) moved
from the client-only building-mod group into the shared "both sides" block
in `thunderstore.toml`, and removed from `CLIENT_ONLY_MODS` in
`scripts/install-mods.sh` -- it now installs on the server too.

Keybind audit: `I` (toggle backpack), bare `Y` (quick-drop), `L` (Demister,
Mistlands-only tier) -- none collide with any existing bind. Bare `Y` and
ExtraSlots' `Alt + Y` are distinct key events, same accepted pattern as
`Q/E/R` vs `Alt + Q/E/R` elsewhere in this pack.

**Config: the old pack's `vapok.mods.adventurebackpacks.cfg` (1.9.13) is NOT
carried forward** -- the 2.0.0 rewrite changed backpack tier naming and added
new drop-scaling settings, so the schema has likely drifted. Will regenerate
fresh on first server boot and be tuned from that copy per the standard
procedure, not from the stale file.

Not yet boot-tested or deployed -- added same session as researched. Full
writeup in README "AdventureBackpacks".

### Added (2026-09-15) -- Zenox-ServerConnect, client-only
One-click main-menu server connect button, replacing QuickConnect's old role.
Client-side, only depends on BepInEx. Audited before adding: no outbound
HTTP/webhook strings in the DLL, single Harmony postfix on the vanilla
main-menu class, nothing else touched. Carries the "AI Generated" tag (396
downloads, 2 days old) -- noted, not a blocker, given how small and easily
audited the whole feature is.
`config/zenox.serverconnect.cfg` holds a real address+password in plain text
and is now gitignored (added to `.gitignore`, same as the old pack's
`quick_connect_servers.cfg`); it does not exist in this working tree and is
never committed. Added to `CLIENT_ONLY_MODS`.

### Changed (2026-09-15) -- Gizmo / ESPME / ATM cooperative config audit
Requested explicitly: verify the three building mods are configured well
*together*, not just each present. Full findings and rationale in README
"Cooperative tuning pass". Summary:
- **Real bug found and fixed, predates this session.** ATM's
  `Searica.Valheim.TerrainTools.cfg` (carried forward verbatim from the old
  111-mod pack) had leftover zero-width-space characters on several section
  headers -- a ConfigurationManager reordering artifact from before that mod
  was dropped. Three keys were orphaned by it (`RadiusModifier`,
  `HardnessModifier`, `Shovel` each had a stray zero-width prefix not present
  in the DLL's real bind name) -- their configured values were silently never
  being read, falling back to mod defaults. Happened to match by coincidence
  (all `true`), which is why it went unnoticed. Stripped from every section
  header and all three keys; re-verified 0/28 keys missing against the 1.4.8
  DLL.
- **ESPME <-> ATM snap-point integration enabled.** ESPME ships per-piece
  extra-snap-point toggles for every ATM terrain-tool variant, all
  individually on at default -- but the master switch,
  `Extra Snap Points: Terrain`, was at its own default of `false`, gating all
  of them off. Flipped to `true`: terrain-tool ghosts now snap to nearby
  building pieces.
- **Six plain-circle ATM tools added** (`raise_v2`, `mud_road_v2`, `path_v2`,
  `paved_road_v2`, `cultivate_v2`, `replant_v2`) -- exist in the 1.4.8 DLL,
  absent from the carried-forward config (predates them). Added explicitly at
  their default (`true`) rather than leaving them to silently auto-populate
  on first regen; both circular and square variants of every tool are now
  available.
- **ATM `MaxRadius` 10 -> 20** (mod's own max). Widens scrollable range only;
  starting radius and scroll-tick size unchanged.
- **Gizmo `isRoofModeEnabled` / `isLocalFrameModeEnabled` false -> true.**
  Both are extra rotation schemes reachable via the existing BackQuote cycle
  key -- previously excluded from the cycle. `isOldRotationModeEnabled` left
  off (superseded, no capability gap).
- No new keybind conflicts: the added tools/modes use existing keys/cycles;
  ServerConnect adds none.
Not yet boot-tested -- server and client both in active use during this
pass. `.r2z` rebuilt; live profile and server not touched.

### Changed (2026-09-15) -- dependency bumps, two packages
`make updates`: 21/23 already current. Both remaining bumps read against their
changelogs; every other shipped config key checked present in the new DLLs.
**Not yet deployed or boot-tested** -- both client and server were in active
use during this pass. Client `.r2z` rebuilt; live profile not patched, server
not redeployed.
- **shudnal-MyLittleUI 1.2.18 -> 1.2.19.** Adds contextual radial-menu hints
  for stations/fermenters, a few new display options, and Seasons-aware
  plant/pickable/beehive timers in the existing hover formatters (Seasons
  isn't in this pack, so that part is inert). **Two config keys removed
  upstream and pruned from `config/shudnal.MyLittleUI.cfg`:**
  `Cooking station next item` (superseded by Valheim's own contextual radial
  menu) and `Cooking station Remove last item` (split out to a new standalone
  mod, `StationItemReturn`). Both were shipped at their default (`true`), so
  nothing customized was lost -- but the remove-last-item convenience itself
  is gone unless `StationItemReturn` is added separately (not done here; not
  asked for).
- **shudnal-ExtraSlots 1.2.5 -> 1.2.6.** "Fixed compatibility with
  Jewelcrafting and other mods that replace crafting, so intentionally
  destroyed items in ExtraSlots are not restored" -- Jewelcrafting isn't in
  this pack, but the underlying crafting-replacement-mod fix is general and
  harmless here. No config changes.

### Added (2026-09-14) -- building mods return, client-only
- **ComfyMods-Gizmo 1.16.0**, **Searica-Extra_Snap_Points_Made_Easy 2.1.0**,
  **Ostrix-AdvancedTerrainModifiersCompatible 1.4.8** (+ its client dependency
  **ValheimModding-Jotunn 2.30.0**). All four go in `CLIENT_ONLY_MODS`; the
  server installs none of them and stays Jotunn-free. 23 packages, 16 on the
  client.
- Gizmo 1.16.0's changelog is "Fixed for v1.0 patch" -- 1.15.0 was the
  bisected 1.0 menu-freeze culprit, this is the upstream fix. ESPME 2.1.0 is
  "Updated for Deep North Update" (1.0.12), no deps.
- The original Searica-AdvancedTerrainModifiers is dead (2024-12, Jotunn
  2.22). The Ostrix fork is ATM 1.4.1 at `e773c62`, same GUID, rebuilt for
  1.0 / BepInEx 5.4.2350 / Jotunn 2.30.0. Chosen because it is the only
  1.0-ready mod with **square hoe and cultivator brushes**, which was the
  hard requirement. Two rule exceptions, recorded in the README: Jotunn is
  back on clients only (the fork works client-side, terrain syncs through
  vanilla RPCs, Jotunn's compat handshake is skipped against a Jotunn-free
  server -- verify on first connect), and the fork carries the "AI Generated"
  tag on what is a compat shim over Searica's original code, not a rewrite.
- Rejected: Heimlife-Flattenheim (its square option is pickaxe-flatten only,
  the hoe radius hook never sets `m_square` -- checked in the DLL; 4 days old),
  VentureValheim Pathside_Assistance + Venture_Terrain_Reset (circular only),
  PreciseRotation / TerrainShaperPlus / PlanBuild (Jotunn for less).
- Configs: the old pack's tuned `bruce.valheim.comfymods.gizmo.cfg`,
  `Searica.Valheim.ExtraSnapPointsMadeEasy.cfg` and
  `Searica.Valheim.TerrainTools.cfg` restored from `main` verbatim. Every key
  verified present in the new DLLs (24/24, ESPME globals 8/8, 22/22; ATM tool
  list unchanged). Keybinds are the old pack's resolved values (Gizmo reset
  V->G, ESPME Manual+ Alt->B, grid F3->F11, Gizmo `ignoreTerrainOpPrefab`
  arbitrates Alt+scroll between Gizmo and ATM); full table in the README.
- Fixed while auditing: ExtraSlots `Quickslot 5 Text` / `Quickslot 6 Text`
  still read "Alt + Q" / "Alt + R" after the binds moved to Alt+U / Alt+Y on
  2026-09-11. Labels now match.
- **Not boot-tested yet.** Added while the server and client were in use.
  Static validation only: all 23 pins exist on Thunderstore, dependency
  closure satisfied, no deprecated packages, new DLLs reference only soft
  GUIDs (searscatalog, configurationmanager). Live test order is in the
  README "Building mods" section. Server not deployed; live profile not
  patched; `.r2z` rebuilt.

### Changed (2026-09-14) -- dependency bumps, six packages
Changelogs read for each; every shipped config key verified present in the
new DLLs (ExtraSlots 213/213, DeathPenalty 4/4, AutoStore 11/11,
ContainerSizes dynamic `InventorySize_{prefab}` keys intact, core 3/3, CCS
Debug 3/3). Nothing to carry forward. **Not yet deployed or boot-tested** --
server in use at the time; the client `.r2z` is rebuilt, the live profile is
not patched.
- **shudnal-ConditionalConfigSync 1.0.6 -> 1.0.8.** 1.0.7: version
  handshakes re-sent immediately before vanilla `PeerInfo`, cutting false
  `HandshakeMissing` rejections after transient transport recovery on
  connect. 1.0.8 (published during this pass): bare mod GUID in
  `HiddenConfigs.cfg` now hides a whole mod's settings; `SyncPolicy.cfg`
  unchanged. Both additive.
- **shudnal-ExtraSlots 1.2.3 -> 1.2.5.** 1.2.4: ValheimPlus compat. 1.2.5:
  ServerCharacters compat (slot placement across reconnects). Neither mod is
  in this pack; inert here.
- **Crystal-DeathPenalty 1.3.0 -> 1.3.1.** "Updated mod package and
  documentation. No functional changes."
- **ArgusMagnus-ServersideQoL 2.0.7 -> 2.0.10.** 2.0.8: an exception in one
  SQoL module no longer kills the others. 2.0.9: "hard crash that stopped all
  SQoL mods" (#214) -- the reason this bump matters. 2.0.10: required by
  PrefabConfigurator (not used here).
- **`_AutoStore` 2.0.0 -> 2.0.8**, **`_ContainerSizes` 2.0.1 -> 2.0.8.**
  "Bugfixes", no detail published; taken with the core bump since the suite
  versions together.

### Changed (2026-09-12) -- dependency bump
- **shudnal-ConditionalConfigSync 1.0.5 -> 1.0.6.** The config-sync library that
  ExtraSlots, MyLittleUI and DeathPenalty all run on, so it got a full changelog
  read rather than a blind bump. 1.0.6 adds an optional *mod-requirement policy*
  system: `ModRequirementMode.Fixed`/`.Conditional` for mod authors, and a new
  server-only `ConditionalConfigSync.ModRequirements.cfg` where `+ ModGuid`
  requires a mod for connecting clients and `- ModGuid` allows clients without it.
  Explicitly backward compatible -- "existing consumers remain fixed by default
  and keep their previous ModRequired behavior without recompilation" -- and the
  wire protocol is unchanged, so a 1.0.5 client can still talk to a 1.0.6 server
  during the rollover. None of this pack's consumers opt into Conditional mode,
  so the new file is inert for us.
  **Config regeneration checked:** after deploy the server generated
  `ModRequirements.cfg` alongside the pre-existing `SyncPolicy.cfg` and
  `HiddenConfigs.cfg`. All three are comment-only templates with no rules -- pure
  defaults with nothing customized to carry forward -- so they are deliberately
  not added to `config/`. `ConditionalConfigSync.Debug.cfg`, the one file this
  pack does ship, is unchanged.
  Deployed and verified live: `Conditional Config Sync 1.0.6` loaded, 15/15
  plugins, 0 NullReference, 0 MissingMethod, no non-graphics errors. Client
  profile and export rebuilt. `make updates`: other 18 packages current.

### Removed
- **All nine Azumatt mods.** None have shipped a Valheim 1.0 build (newest is
  AzuExtendedPlayerInventory, 2026-08-31, pre-1.0): AzuAutoStore, AzuCraftyBoxes,
  AzuContainerSizes, AzuExtendedPlayerInventory, AzuHoverStats, AzuAreaRepair,
  AzuMiscPatches, AAA_Crafting, Recycle_N_Reclaim.
- **Jotunn, and everything that needed it** (VNEI, MissingPieces,
  AdventureBackpacks). The new dependency graph has no Jotunn at all.
- Building mods (Gizmo, ExtraSnapPointsMadeEasy, AdvancedTerrainModifiers),
  combat (ProjectileTweaks, ShieldBash), Seasons, SmartSkills, TargetPortal,
  SpeedyPaths, StumpsAreOneHp, LocalizationCache, Groups, MultiUserChest,
  Quick Stack Store, ComfyAutoRepair, ConfigurationManager, farming mods.

### Added
- **ArgusMagnus ServersideQoL 2.0.x, seven modules, server-side only** - core,
  `_AutoStore`, `_ContainerSizes`, `_AutoProcess`, `_LetItFloat`, `_JustSleep`,
  `_MultiplayerTweaks`. Server-authoritative and compatible with unmodded and
  console clients, so they cost players nothing to install. Between them they
  replace AzuAutoStore, AzuContainerSizes, AutomaticFuel, Venture Floating
  Items, SleepSkip, NetworkTweaks and TimeoutLimit.
- **shudnal-ExtraSlots 1.2.3** replaces AzuExtendedPlayerInventory (equipment +
  quick slots). Fits the existing shudnal/ConditionalConfigSync stack.
- **Toxo-CraftFromChests 0.4.0** replaces AzuCraftyBoxes.
- **TastyChickenLegs-RecyclePlus 1.3.2** replaces Recycle_N_Reclaim and Quick
  Stack Store's trash function.
- MyLittleUI now also covers AzuHoverStats (tooltips) and AAA_Crafting
  (multicraft), so both came out with no functional loss.

### Changed
- **`scripts/export-profile.sh` learned `SERVER_ONLY_MODS`** - server-side
  packages are excluded from the generated client profile, so `make profile`
  emits 10 packages while the toml carries 17. Profile is now named
  `Fimbulwinter-Lite-v<version>`.
- **`CLIENT_ONLY_MODS` in `scripts/install-mods.sh`** trimmed to the three
  genuinely client-only mods: MyLittleUI, HUDCompass, RecyclePlus.
- TeleportEverything dropped entirely in favour of the vanilla
  `-modifier portals casual` world modifier - same capability, zero mods.

### Evaluated and rejected
- **Swmarly-SwmarlyValheimQOL 1.0.5 -- not added.** Deployed alongside
  ServersideQoL and boot-tested live: the two load together cleanly (14 plugins,
  0 NullReference, 0 MissingMethod, no Harmony conflict warnings, server reached
  "Opened Steam server"), so there is no *load-time* incompatibility. It was
  rejected on two other grounds.
  First, it duplicates four behaviours this pack already has -- floating items
  (`ServersideQoL_LetItFloat`), sleep-skip voting (`_JustSleep`), no-rain-damage
  (JoelOliMclean-NoRainDamage, both patching `WearNTear`) and eternal fires
  (`_AutoProcess`, both touching `Fireplace`). Duplicate implementations of one
  behaviour do not error, they double-apply, and that only surfaces in gameplay
  where a boot test cannot see it.
  Second, it carries Thunderstore's "AI Generated" tag with 1,692 downloads and
  a two-day-old release, against ServersideQoL's 38,783 and a months-long
  history, and registers 47 Harmony patch classes. This is the same test the
  v1.4.2 entry applied when rejecting VitByr-VBNetTweaks.
  Worth revisiting if it matures: it is the only 1.0-ready package found that
  covers MultiUserChest, ComfyAutoRepair, WieldEquipmentWhileSwimming and
  SpeedyPaths, none of which have a 1.0 build.

### Not tested
- Selection came from Thunderstore metadata (publish dates, dependency graphs,
  deprecation flags), not from running the game. During the 1.0 investigation
  both Gizmo and Groups loaded cleanly and still broke the main menu and
  Settings screen, so metadata alone is not sufficient - boot-test before use.


## [vanilla] - UNRELEASED - branch `vanilla`, local only, DO NOT PUBLISH

> Not a release. This branch is a deliberate teardown of the pack to a
> BepInEx-only bootstrap for Valheim 1.0.0, so we can play together while the
> mod ecosystem catches up to 1.0.0 "Deep North". Do not merge to `main`, do
> not tag, do not publish. `main` (v1.4.4) and `2.0.0-rc` still hold the real
> modpack.

### Removed
- **All 57 gameplay mods.** `thunderstore.toml` now carries exactly one
  dependency: `denikson-BepInExPack_Valheim 5.4.2350`. The loader is present
  and ready so mods can be layered back on individually as their authors ship
  1.0-compatible builds; nothing else ships.
- **All 57 mod config files.** `config/` is down to `BepInEx.cfg` alone.

### Changed
- **`config/BepInEx.cfg` ships with the console fully off** --
  `[Logging.Console] Enabled = false`, `PreventClose = false` and
  `ForceBepInExTTYDriver = false`. Under Valheim 1.0's Unity 6 engine that
  forced TTY console renders as a non-closable overlay that swallows all mouse
  and keyboard input. Disk logging is untouched.
- **`scripts/export-profile.sh` names the profile `Fimbulwinter-Vanilla-v<version>`**
  (output `dist/Fimbulwinter_Vanilla-v<version>-profile.r2z`) so a `make profile`
  import cannot collide with the modded r2modman profiles.
- **`versionNumber` is `1.0.0`** -- it tracks the targeted Valheim release line
  (1.0 "Deep North"), not a pack release number. SteamCMD always installs
  whatever is current on the stable branch, so this is a target, not a pin.

### Added
- **New self-contained Pelican egg** (`server/fimbulwinter-lite-egg.yaml`),
  replacing the thin GitHub-bootstrap egg on this branch. It fetches no scripts
  from the repo, because the `vanilla` branch is local-only and a remote
  bootstrap would 404 and fail the install. It installs Valheim via SteamCMD and
  BepInEx straight from Thunderstore, then purges `BepInEx/plugins` and
  `BepInEx/patchers` (`PURGE_PLUGINS`, default on) so a reinstall over a
  previously modded server is provably mod-free. Carries its own UUID so it
  coexists with the modded egg, and deliberately has **no `update_url`** -- with
  one pointing at `main`, the panel could silently "update" this egg into the
  modded one.
- **Every world modifier as its own panel field**, with the accepted values
  enumerated in each variable's validation rules: `PRESET` (7 presets),
  `MODIFIER_COMBAT`, `MODIFIER_DEATHPENALTY`, `MODIFIER_RESOURCES`,
  `MODIFIER_RAIDS`, `MODIFIER_PORTALS`, the four `-setkey` toggles
  (`KEY_NOBUILDCOST`, `KEY_PLAYEREVENTS`, `KEY_PASSIVEMOBS`, `KEY_NOMAP`) and
  `EXTRA_SETKEYS` for keys Iron Gate adds later. An empty field omits the flag
  entirely, which is the vanilla default for that dial.
- **Correct modifier argument ordering, enforced by construction.** A `-preset`
  emitted after `-modifier` flags silently overwrites them, so the startup
  command always builds `-preset` first, then modifiers, then setkeys, then
  `-instanceid`/`-crossplay`, with `EXTRA_ARGS` last so it can override
  anything. The assembled arguments are echoed each boot as
  `[STARTUP] World args:`. Verified by dry-running the startup command with all
  fields empty, all fields set, and the loader disabled.
- **`BEPINEX_ENABLED`** -- flip to 0 to run 100% pure vanilla without a
  reinstall; doorstop simply is not injected and the loader stays on disk.
- **`BEPINEX_VERSION`** -- `latest` (resolved from the Thunderstore API at
  install time) or a pinned version.
- **`ADMIN_STEAMIDS`** -- space-separated Steam64 IDs written to
  `adminlist.txt` on every boot, so admins get the F5 console for
  `setworldmodifier` / `setkey` / `removekey` on a live world (F2 shows what is
  actually active).
- **More server parameterization**: `INSTANCE_ID` (`-instanceid`), `SAVE_DIR`
  (defaulted to the existing server's `/home/container/saves` so the current
  world is found as-is), `SAVE_INTERVAL`, and `EXTRA_ARGS` raw passthrough.


## [1.4.4] - 2026-09-08

### Changed
- Azumatt-AzuExtendedPlayerInventory bumped 2.4.4 -> 2.4.8:
  - 2.4.5: EpicLoot API update (not used by this pack) and a fix for a
    localization-init race that could throw a NullReferenceException blamed
    on other mods.
  - 2.4.6: adds AzuEPI's own item/slot favoriting system (new
    `[10 - Favoriting]` config section -- modifier key, border colors,
    tooltip text). **Confirmed inert in this pack**: read the mod's source
    (`FavoritingMode.IsExternalFavoritingModLoaded()`) and it auto-disables
    itself whenever AzuAutoStore or Quick Stack Store is installed, both of
    which we already run -- favoriting stays owned by AzuAutoStore exactly
    as before, this section's `LeftAlt` modifier key never actually
    activates, so it needed no keybind-conflict audit despite reusing Alt.
  - 2.4.7: player-preview idle animation polish, cosmetic only.
  - 2.4.8: adds `One Utility Item At A Time` (new key in
    `[4 - Special Equipment Slots]`, default Off) -- restores vanilla
    one-utility-item exclusivity if enabled. Left at the shipped default
    (Off) to keep this pack's whole point of dedicated utility slots intact.
  - No balance-affecting change; stats-panel numbers only, confirmed by
    upstream changelog.
- JereKuusela-Server_devcommands bumped 1.108.0 -> 1.109.0 -- console
  history/force-enable fixes, an admin permission-check timing fix, and
  dropping the Steamworks dependency (helps non-Steam hosts). No new config
  keys; `server_devcommands.cfg`/`binds.yaml`/`permissions.yaml` schema
  unchanged, verified against the changelog.

## [1.4.3] - 2026-08-19

### Changed
- korCaptain-NullReferenceFix 1.0.6 -> 1.0.17 -- picks up several more
  Harmony cleanup patches added since 1.0.6: a `ZSFX` engine gap where
  sound-effect instances without a `ZNetView` were never destroyed after
  finishing, which leaked a permanent per-frame cost in `MonoUpdaters.Update()`
  and could eventually freeze the game (most visible with sound-heavy
  skill/weapon mods); a fix for a recurring TextMeshPro "LiberationSans SDF
  Font Asset was not found" warning from unfonted TMP text objects; and a
  set of non-Latin-script TMP font fallback registrations (Arabic, Korean,
  Japanese, etc.) that don't affect this pack's English-only content. No
  config, no keybinds -- same config-less DLL as before.
- Azumatt-AzuExtendedPlayerInventory 2.4.2 -> 2.4.4 -- stats-panel display
  accuracy pass (Skill Raise Speed, Speed Modifier, Jump Height, Run
  Stamina, resistances, and other HUD numbers were computed or labeled
  incorrectly; actual gameplay values were never affected, only what was
  shown) plus an equip-animation flicker fix and an AdventureBackpacks
  stacking fix. No config or balance change.
- Azumatt-Recycle_N_Reclaim 1.4.0 -> 1.4.1 -- fixes armor recycling
  silently returning only 75% of materials when a bad `Armor: 0.75`
  override shipped active in 1.4.0's default template, and fixes an
  omitted `groups:` YAML section breaking the reclaim list instead of
  defaulting to empty. **Verified our shipped**
  **`Azumatt.Recycle_N_Reclaim_ExcludeLists.yml` has neither issue** (no
  `recycleRates:` section, `groups:` present and populated) -- update
  applies cleanly with no manual config fix needed.

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
