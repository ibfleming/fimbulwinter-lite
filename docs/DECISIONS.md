# Decisions

Why things are the way they are in Fimbulwinter Lite 2.0.0. This is the
research/rationale record that used to live inline in README.md and
CHANGELOG.md -- moved here so those stay readable for players, while the
evidence behind each call stays available for whoever maintains this pack
next. Git history has the verbatim, timestamped version of all of this;
this file is the distilled version.

## The 2.0.0 rebuild

Valheim 1.0 "Deep North" (2026-09-09) broke most of the old 111-/58-mod
pack's dependency graph, especially anything touching Jotunn (VNEI,
MissingPieces, AdventureBackpacks) and the nine Azumatt mods (none had
shipped a 1.0 build). Rather than patch the old pack mod-by-mod, it was
rebuilt from scratch around two rules: zero Azumatt, and push as much QoL
onto the dedicated server as possible so clients stay near-vanilla. That
took it from 58 packages down to as few as 17 before the building mods and
AdventureBackpacks came back.

## Jotunn: removed, then partially reinstated

Jotunn was dropped entirely in the initial rebuild specifically because it
was the shared dependency dragging in VNEI/MissingPieces/AdventureBackpacks,
none 1.0-ready at the time. It came back twice, for different reasons:

- **ComfyMods-Gizmo + Searica-Extra_Snap_Points_Made_Easy** came back
  client-only once both had confirmed 1.0 builds (Gizmo 1.16.0's changelog:
  "Fixed for v1.0 patch" -- 1.15.0, built for 0.220.3, was the version
  bisected as the actual 1.0 main-menu-freeze culprit during the initial
  1.0 compat investigation).
- **The AdvancedTerrainModifiers slot** needed square hoe/cultivator
  brushes as a hard requirement. The original Searica-AdvancedTerrainModifiers
  is dead (2024-12, pinned to Jotunn 2.22). Alternatives evaluated:
  `Heimlife-Flattenheim` (no Jotunn, but its `Shape: Square/Circle` option
  only applies to its pickaxe-flatten tool -- confirmed in the DLL that the
  hoe/cultivator radius hook never sets `m_square` -- and it was 4 days old
  at ~1K downloads); the VentureValheim pair `Pathside_Assistance` +
  `Venture_Terrain_Reset` (trusted author, no deps, but circular brushes
  only -- `Pathside` clones vanilla `TerrainOp.Settings` and only touches
  the four radius fields); `disregardthatisuck-PreciseRotation`,
  `PONEIS-TerrainShaperPlus`, `MathiasDecrock-PlanBuild` (all pull in
  Jotunn or HookGenPatcher for less than the fork gives). Landed on
  `Ostrix-AdvancedTerrainModifiersCompatible` 1.4.8 -- a fork of ATM 1.4.1
  at commit `e773c62`, same plugin GUID, the only 1.0-ready option with
  square tools. It runs client-only (its own README: works without Jotunn
  on the server, terrain syncs through vanilla RPCs); Jotunn's own
  compat handshake is skipped when the server doesn't run it. Carries
  Thunderstore's "AI Generated" tag, but on a compatibility shim over
  Searica's original gameplay code, not an AI-written rewrite -- different
  case than SwmarlyValheimQOL/VBNetTweaks, which were rejected for exactly
  that reason (see "Mods evaluated and rejected" below).
- **Vapok-AdventureBackpacks** reopened the bigger question: unlike the ATM
  fork, its own README states it's *required on both client and server*
  with built-in version checking. That puts Jotunn back as a real **server**
  dependency -- the exact thing the original rebuild avoided. Added anyway,
  a deliberate tradeoff accepted after flagging it explicitly: this is now
  the one mod in the pack that can lock a mismatched client out entirely.

## ATM config: a real bug, found by accident

While auditing whether Gizmo/ESPME/ATM cooperate well configuration-wise,
`Searica.Valheim.TerrainTools.cfg` (carried forward from the old 111-mod
pack) turned out to have leading zero-width-space characters on several
section headers -- almost certainly a ConfigurationManager section-reorder
artifact from when that mod ran alongside ATM in the old pack. Three keys
were affected badly enough to be orphaned outright: `RadiusModifier`,
`HardnessModifier` and `Shovel` each carried a stray zero-width prefix not
present in the DLL's real (plain) bind name -- confirmed via `strings -e l`
against the 1.4.8 DLL. Their configured values were silently never being
read; they happened to match the mod's own defaults (`true`), which is
exactly why nobody noticed for months. Fixed by stripping every zero-width
character from section headers and from those three keys; re-verified
0/28 keys missing against the DLL afterward. Lesson: a config edit to this
file should be confirmed live, not trusted from the file alone.

Same audit found ESPME already ships per-piece extra-snap-point toggles
for every ATM terrain-tool variant (`raise_v2`, `paved_road_v2_square`,
`cultivate_v2_path`, etc.), all individually on at default -- genuine
built-in cooperation between the two mods -- but gated off entirely by one
master switch, `Extra Snap Points: Terrain`, sitting at its own default of
`false`. Flipped on. Also found six plain-circle ATM tool variants
(`raise_v2`, `mud_road_v2`, `path_v2`, `paved_road_v2`, `cultivate_v2`,
`replant_v2`) existed in the DLL but were absent from the carried-forward
file (predates them); added explicitly at their default rather than
leaving them to silently auto-populate on next regen.

## RecyclePlus removed, then replaced

`TastyChickenLegs-RecyclePlus 1.3.2` recycled a plain club (6 wood) into a
Wooden Battle Idol, 100% reproducibly. Cause: Valheim 1.0's Forge of
Potential added an `Upgrader (Refinement Forge)` station whose recipes
consume idols; RecyclePlus resolves materials via `GetRecipe` and was
picking up the refinement recipe instead of the crafting recipe. No
upstream fix existed (1.3.2 was latest), and nothing in its config could
gate it (`ReturnResources` only scales the return rate, no exclusion list)
-- removed outright as a direct violation of "no game-breaking shortcuts."

Replaced by `cjayride-RecycleItemsIntoParts` at user request, with an
explicit caveat that any recycle mod resolving through `GetRecipe` was a
suspect for the same bug until proven otherwise. Its own changelog (1.7.2)
independently lists the fix: a `Discarding {item}` code path that deletes
the source item but discards an idol result instead of returning it,
rather than blocking the recycle. Passed the club test live (2026-09-16):
crafted a plain club, recycled it, wood back and nothing else. Confirmed
via the DLL (8 config keys total, nothing hidden) that there's no
"discard anything regardless of recipe" option -- it needs some resolvable
recipe to act at all, so it was never going to be a general trash function.

## Mods evaluated and rejected

- **Swmarly-SwmarlyValheimQOL 1.0.5** -- boot-tested clean alongside
  ServersideQoL (no load-time conflict), but duplicates four behaviours
  already covered (floating items, sleep-skip voting, no-rain-damage,
  eternal fires) and carries the "AI Generated" tag at ~1.7K downloads and
  a two-day-old release against ServersideQoL's ~39K and months of
  history. Worth revisiting if it matures -- it's the only found package
  covering MultiUserChest/ComfyAutoRepair/WieldEquipmentWhileSwimming/
  SpeedyPaths, none of which have 1.0 builds.
- **VitByr-VBNetTweaks** -- rejected as a NetworkTweaks companion: its own
  README lists our exact NetworkTweaks GUID as a hard incompatibility, and
  it carries the "AI Generated" tag at ~1.5K downloads vs NetworkTweaks'
  ~26K/stable-since-2025.

## Keybind history

Several binds moved from their mod defaults during the initial config
pass and later mod additions; the reasoning, so it isn't re-litigated:

- ExtraSlots shipped two duplicate binds against itself (`Quickslot 5`/
  `Food 1` both `Alt+Q`; `Quickslot 6`/`Food 3` both `Alt+R`). Quickslots
  moved to `Alt+U`/`Alt+Y` rather than the food slots, to keep the food row
  coherent and preserve muscle memory from the old pack's AzuEPI binds.
- HUDCompass's `Alt+C` collided with ExtraSlots `Quickslot 3` -- moved to
  bare `J`.
- ExtraSlots' `Rebind Connect Panel` was wrongly moved off `F2` in an
  earlier audit pass, under the mistaken belief it conflicted with
  something -- it's actually vanilla's own F2 performance HUD (FPS/ping/
  ZDOs), exposed through ExtraSlots' config. Moving it made the HUD
  disappear, which players noticed. Reverted to `F2`.
- Gizmo `resetRotationKey` moved `V` -> `G` (`V` is vanilla voice chat).
  ESPME's Manual+ toggle moved `LeftAlt` -> `B` (LeftAlt is Gizmo's z-rotate
  hold and ATM's radius-scroll modifier); grid snap moved `F3` -> `F11`
  (F3 was ConfigurationManager's bind in the old pack).
- Gizmo/ATM both wanting `LeftAlt`+scroll in build mode is resolved by
  Gizmo's own `ignoreTerrainOpPrefab = true` -- Gizmo simply doesn't
  activate on terrain-modifying tools, so the scroll goes to ATM whenever
  a terrain tool (not the hammer) is equipped.
- Server_devcommands' `binds.yaml` had a dead `/creative` command left over
  from the old 111-mod pack (verified: no such command exists in the
  shipped DLL). Admin bundle (`debugmode`+`nocost`+`god`) runs on `O`,
  `fly` on `K` -- plain letters rather than F-keys deliberately, since
  F9-F12 are common Steam Input/overlay/macro-software hotkeys that can
  intercept the keypress before Valheim sees it (confirmed live with F9).

## Test log (superseded by "it works" -- kept for the record)

- 2026-09-11: first full boot of the rebuilt pack. Server 13/13 plugins,
  client 9/9, 0 exceptions either side, Settings menu opened clean (the
  exact failure Smoothbrain-Groups caused in the old pack). One real bug
  found by testing: the egg accepted `normal` as a `-modifier` value, which
  the game rejects (modifiers express "normal" by omission, not by name).
  Fixed in the egg's validation rules.
- 2026-09-15: first server boot with Jotunn present on this branch (for
  AdventureBackpacks). 17/17 plugins, Jotunn's ModCompatibility/
  Synchronization/Network/Localization managers all initialized clean, 0
  exceptions.
- 2026-09-16: club test passed on RecycleItemsIntoParts (see above);
  AdventureBackpacks and the building mods confirmed working in a live
  two-player session, including the ModRequired connect path.
