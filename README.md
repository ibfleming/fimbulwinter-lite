# Fimbulwinter Lite 2.0.0 - server-side-first QoL for Valheim 1.0

**Branch: `lite-minimal`. Temporary, local-only. Never pushed to `main`, never tagged, never published.**

A ground-up rebuild of the pack for Valheim 1.0 "Deep North", built on two rules:

1. **Zero Azumatt mods.** None of the nine in the old pack have shipped a 1.0 build.
2. **If the server can do it, the server does it.** Players install as little as possible.

**23 packages, down from 58.** Every package verified against the Thunderstore API as published
on/after 2026-09-09 (Valheim 1.0.0) - except the two pure serialization libraries, which contain no
game code. **The server runs no Jotunn.** Jotunn exists on clients only, as the dependency of one
building mod (see "Building mods" below).

## The split

Only 16 packages reach players. The other 7 live on the dedicated server and are excluded from the
client profile automatically (`SERVER_ONLY_MODS` in `scripts/export-profile.sh`).

### Client (16) - `make profile`

| Package | Version | Role |
|---|---|---|
| denikson-BepInExPack_Valheim | 5.4.2350 | loader |
| ValheimModding-YamlDotNet | 16.3.1 | library |
| shudnal-ConditionalConfigSync | 1.0.6 | server-enforced config |
| **shudnal-MyLittleUI** | 1.2.18 | tooltips, production timers, chest preview, multicraft, weather |
| **shudnal-ExtraSlots** | 1.2.3 | equipment + quick slots |
| **Toxo-CraftFromChests** | 0.4.0 | craft/build/fuel from nearby chests |
| **Neobotics-HUDCompass** | 1.2.0 | compass bar |
| **JoelOliMclean-NoRainDamage** | 1.3.0 | no weather decay on builds |
| **korCaptain-NullReferenceFix** | 1.0.20 | stability |
| **JereKuusela-Server_devcommands** | 1.113.0 | admin console on a dedicated server (see below) |
| **Crystal-DeathPenalty** | 1.3.0 | tunes skill loss on death -- replaces SmartSkills |
| **cjayride-RecycleItemsIntoParts** | 1.7.3 | recycle items into parts (drag + `Delete`) -- see caveat |
| **ComfyMods-Gizmo** | 1.16.0 | free build-piece rotation on all three axes |
| **Searica-Extra_Snap_Points_Made_Easy** | 2.1.0 | extra snap points, manual/grid snapping |
| ValheimModding-Jotunn | 2.30.0 | library -- **client only**, needed by the terrain fork |
| **Ostrix-AdvancedTerrainModifiersCompatible** | 1.4.8 | square hoe/cultivator tools, radius + hardness scroll, precision raise, terrain reset |

### Server only (7) - players install none of these

| Module | Version | Replaces |
|---|---|---|
| ArgusMagnus-ServersideQoL | 2.0.7 | (suite core) |
| `_AutoStore` | 2.0.0 | AzuAutoStore |
| `_ContainerSizes` | 2.0.1 | AzuContainerSizes |
| `_AutoProcess` | 2.0.0 | AutomaticFuel |
| `_LetItFloat` | 2.0.4 | Venture Floating Items |
| `_JustSleep` | 2.0.0 | SleepSkip |
| `_MultiplayerTweaks` | 2.0.0 | NetworkTweaks + TimeoutLimit |

ServersideQoL is server-authoritative and works with **unmodded and console clients**, so none of the
above costs a player anything to install.

## Building mods (added 2026-09-14)

The three building mods the old pack was built around are back, now that all three have 1.0
builds. All are **client-only** -- the server does not run any of them, or Jotunn.

| Mod | Why this one |
|---|---|
| ComfyMods-Gizmo 1.16.0 | Changelog: "Fixed for v1.0 patch". 1.15.0 (built for 0.220.3) is the version that broke the 1.0 main menu during the September bisection; 1.16.0 is the upstream fix. No dependencies. |
| Searica-Extra_Snap_Points_Made_Easy 2.1.0 | "Updated for Deep North Update", 1.0.12. Author notes new 1.0 pieces get automated snap points only, no hand-placed ones yet. No dependencies. |
| Ostrix-AdvancedTerrainModifiersCompatible 1.4.8 | The original Searica-AdvancedTerrainModifiers is dead (last release 2024-12, pinned to Jotunn 2.22). This is a fork of ATM 1.4.1 at commit `e773c62`, same plugin GUID, rebuilt for Valheim 1.0 / BepInEx 5.4.2350 / Jotunn 2.30.0. **It is the only 1.0-ready mod that gives square hoe and cultivator brushes**, which was the deciding requirement. |

Two deliberate exceptions to this pack's rules, recorded here so they are not re-litigated:

- **Jotunn is back, on clients only.** The fork's README: *"does work as a client-side only mod and only
  needs to be installed on the server if you wish to enforce configuration settings."* Terrain
  changes propagate through vanilla's own terrain RPCs, so other players see them without the mod. Jotunn
  performs its mod-compatibility handshake only when both sides run it; with a Jotunn-free server it is
  skipped. **Verify on the first connect** that a client with the fork joins the server cleanly.
- **The fork carries Thunderstore's "AI Generated" tag.** Unlike SwmarlyValheimQOL and VBNetTweaks
  (rejected: AI-written from scratch), this tag is on a compatibility shim over Searica's original
  gameplay code -- the square tools, precision raise and reset are the real ATM 1.4.1 implementation.
  9.9K downloads across eight 1.0-era releases, the most-iterated terrain mod on Thunderstore.

Alternatives checked and passed over: `Heimlife-Flattenheim 1.0.0` (no Jotunn, but its `Shape:
Square/Circle` option applies only to its pickaxe-flatten tool -- the hoe/cultivator radius hook never
sets `m_square`, confirmed in the DLL; also four days old at 1K downloads); the VentureValheim pair
`Pathside_Assistance` + `Venture_Terrain_Reset` (trusted author, no deps, but circular brushes only --
Pathside clones vanilla `TerrainOp.Settings` and touches just the four radius fields);
`disregardthatisuck-PreciseRotation`, `PONEIS-TerrainShaperPlus`, `MathiasDecrock-PlanBuild` (Jotunn,
and for PlanBuild HookGenPatcher, for less than the fork gives).

Configs are the old pack's tuned files carried forward verbatim -- every key was checked against the
new DLLs and all still exist (Gizmo 24/24, ATM 22/22, ESPME global keys 8/8; the ATM tool list is
unchanged). Key values: Gizmo `snapDivisions = 16`, `ignoreTerrainOpPrefab = true` (no gizmo on hoe /
cultivator / shovel, so `Alt + scroll` goes to ATM's radius control when a terrain tool is out); ATM
`MaxRadius = 10`, every square/precision/path tool enabled, shovel on; ESPME manual snapping on all
piece classes.

**Not yet boot-tested on this branch** -- added while the server was in use. Test order when free:
client boot -> main menu -> Settings opens -> join server -> place a piece with Gizmo -> square-pave a
tile -> confirm the other player sees the terrain change.

## Why Server_devcommands is required

Vanilla gates every cheat command behind `Terminal.IsCheatsEnabled()`:

```csharp
if (!m_cheat) return false;
if (ZNet.instance == null) return false;
return ZNet.instance.IsServer();   // must BE the server
```

On a dedicated server a connected player is never the server, so `god`, `fly` and `debugmode` are
rejected with "not valid in the current context" **no matter what adminlist.txt says** -- being an
admin grants kick/ban, not client cheats. `devcommands` still reports "Dev commands: True" because it
only flips a local flag, which makes the failure look like a permissions problem when it is not.

Server_devcommands patches that gate (it references `IsCheatsEnabled`, `TryRunCommand`,
`ConsoleCommand.IsValid`, `m_cheat` and `RemoteCommand`). It must be installed on **both** sides: the
console it patches is client-side, while permissions are enforced server-side.

`Automatic devcommands = false` is kept from the old pack -- admins run `devcommands` explicitly
rather than having it enable on join.

## ServersideQoL tuning

The modules ship largely inert -- AutoStore in particular had auto-pickup off, sorting off and its
emote trigger disabled, so it did nothing at all. All seven are now configured. Values come from the
old pack's own tuned configs wherever an equivalent existed, rather than invented numbers.

| Module | Setting | Value | Why |
|---|---|---|---|
| AutoStore | `AutoPickup` | true | was off -- the headline feature |
| AutoStore | `AutoPickupRange` | 20 | parity with old AzuAutoStore (mod default 64 is most of a base) |
| AutoStore | `StackInventoryIntoContainersEmote` | -2 (any emote) | was -1/disabled; the mod recommends "any" as most reliable over crossplay |
| AutoStore | `AutoSort` | true | |
| AutoStore | `PickedUpMessageType` | TopLeftNear | feedback when something is auto-stored |
| AutoProcess | `FeedFromContainersRange` | 15 | parity with old AutomaticFuel (mod default 4 is uselessly tight) |
| AutoProcess | `CapacityMultiplier` / `TimePerProductMultiplier` | **1 / 1** | deliberately untouched -- no smelting speed or capacity cheats |
| JustSleep | `RequiredPlayerPercentage` | 51 | old SleepSkip was majority-rules, not the mod's unanimous 100 |
| MultiplayerTweaks | `AssignInteractablesToClosestPlayer` | true | prevents ore loss from networking issues |
| MultiplayerTweaks | `AssignMobsToClosestPlayer` | true | fixes dodge/parry desync |
| MultiplayerTweaks | `AssignShipsToCaptain` | true | fixes ship control desync |
| MultiplayerTweaks | `ForcePlayerMapPin` | **false** | left vanilla -- a visibility change, not a fix |
| ContainerSizes | wood `5x3`, reinforced `6x5`, blackmetal `8x6`, karve `4x2`, longship `6x4` | | exact parity with the old AzuContainerSizes values |

Everything the old pack did not touch stays vanilla: personal chest, barrel, cart, wardrobe, grausten
chest, Ashlands ship, pots and gifts. The `+` suffix (a container that expands forever while holding a
single item type) is **not used anywhere** -- it is not a Vanilla+ behaviour.

The three MultiplayerTweaks ownership options are the closest thing in this pack to the
NetworkTweaks/TimeoutLimit role from the old one: they are desync fixes, not conveniences.

## RecyclePlus removed (exploit)

`TastyChickenLegs-RecyclePlus 1.3.2` was pulled after live testing. **Recycling a plain club returned a
Wooden Battle Idol, 100% reproducibly** -- a club costs six wood, so it was an infinite generator for
one of Valheim 1.0's rarest materials.

Cause: 1.0 added the Forge of Potential, implemented in `assembly_valheim` as an `Upgrader
(Refinement Forge)` station whose recipes consume idols. RecyclePlus resolves an item's materials via
`GetRecipe` and is picking up the refinement recipe rather than the crafting recipe, so it hands back
the idol. That means it is very unlikely to be clubs alone -- any refinable weapon, tool or staff is a
candidate.

No upstream fix: 1.3.2 is the latest published version. Removing it is the only safe option, since it
directly breaks design principle 1 (no game-breaking shortcuts) and nothing in its config can gate it
(`ReturnResources` only scales the return rate, there is no exclusion list).

The pack now has **no recycle or trash function**. Candidates if you want one back -- each needs the
club test run against it first, because they may share the same 1.0 recipe-resolution bug:

```
cjayride-<DiscardInventoryItem fork>   1.7.3   "Updated for Valheim 1.0"
Ketanol-<RecyclePlus-based>            1.0.1   explicitly "Based on RecyclePlus" -- likely same bug
MainStreetGaming-<recycler>            1.0.1
```

## Caveat: cjayride-RecycleItemsIntoParts

Added at user request to fill the recycle gap left by RecyclePlus. **Not yet cleared by the club
test.** RecyclePlus was removed because recycling a plain club returned a Wooden Battle Idol 100% of
the time -- Valheim 1.0's Forge of Potential (`Upgrader (Refinement Forge)`) registers recipes that
consume idols, and a recycle mod resolving materials through `GetRecipe` can pick those up instead of
the crafting recipe. Any recycle mod is a suspect until proven otherwise.

Before trusting it: craft a plain club from wood, recycle it, and confirm you get **wood back and
nothing else**. If an idol appears, remove it the same way RecyclePlus was removed.

It also carries Thunderstore's "AI Generated" tag -- the same flag that got VitByr-VBNetTweaks
rejected in v1.4.2.

## Crystal-DeathPenalty tuning

Shipped in `config/dev.crystal.deathpenalty.cfg`, section `[Death]`. All four keys are
`AlwaysServerControlled` via ConditionalConfigSync -- the server copy wins, change it with
`scripts/deploy.sh configs`.

| Key | Value | Vanilla | Why |
|---|---|---|---|
| `SkillLossPercent` | **2** | 5 | the one deliberate dial -- see below |
| `MercyEffectDuration` | 600 | 600 | post-death no-loss window, blocks chained-death spirals |
| `SafetyEffectDuration` | 50 | 50 | "Corpse Run" buff on looting your tombstone |
| `ResetLevelProgress` | true | true | partial next-level progress still wiped |

**Why 2.** Vanilla 5% compounds harshly on a fresh world running combat hard (150% enemy damage,
85% player damage). The old pack's SmartSkills gave "75% recovery", roughly 1.25% effective -- but
that was paired with combat *veryhard*. Combat is a notch easier now, so a slightly higher loss keeps
the overall stakes of dying about where they were: a level-30 skill loses ~0.6 levels per death.
Noticeable, recoverable. Untested in play -- adjust after a few deaths if it feels off.

## Keyboard Shortcuts

Audited 2026-09-11 against the mods' freshly generated configs; building mods audited 2026-09-14.
MyLittleUI, CraftFromChests, NoRainDamage, NullReferenceFix and Jotunn declare **no** keybinds at all,
so the entire bind surface is below.

| Key | Mod | Action | Context |
|-----|-----|--------|---------|
| `Alt + Z / X / C / V` | ExtraSlots | Quick slots 1-4 | Anywhere |
| `Alt + U` | ExtraSlots | Quick slot 5 | Anywhere (moved off `Alt + Q`, see below) |
| `Alt + Y` | ExtraSlots | Quick slot 6 | Anywhere (moved off `Alt + R`, see below) |
| `Alt + 1 / 2 / 3` | ExtraSlots | Ammo slots 1-3 | Anywhere |
| `Alt + Q / E / R` | ExtraSlots | Food slots 1-3 | Anywhere |
| `Alt` (hold) | ExtraSlots | Drag item between equipment slots | Inventory open |
| `J` | HUDCompass | Toggle the compass bar | Anywhere (moved off `Alt + C`, see below) |
| `Delete` | RecycleItemsIntoParts | Recycle the item on the cursor | Inventory open |
| `LeftShift` (hold) + scroll | Gizmo | Rotate piece on X axis | Build mode |
| `LeftAlt` (hold) + scroll | Gizmo | Rotate piece on Z axis | Build mode (hammer only -- ignored for terrain tools) |
| `G` / `T` | Gizmo | Reset selected axis / reset all axes | Build mode |
| `` ` `` (BackQuote) | Gizmo | Cycle rotation mode | Build mode |
| `P` | Gizmo | Copy targeted piece's rotation | Build mode |
| `PageUp` / `PageDown` | Gizmo | Snap divisions +/- (16 per 180 deg shipped) | Build mode |
| `B` | ExtraSnapPointsMadeEasy | Toggle Manual+ snap mode | Build mode |
| `CapsLock` | ExtraSnapPointsMadeEasy | Toggle Manual snap mode | Build mode |
| `F11` / `F4` | ExtraSnapPointsMadeEasy | Toggle grid snap / cycle grid precision | Build mode |
| `Q` / `E` | ExtraSnapPointsMadeEasy | Iterate placing / targeted snap points | Manual snap modes only |
| `LeftAlt` (hold) + scroll | AdvancedTerrainModifiers | Change tool radius | Hoe / cultivator / shovel out |
| `LeftControl` (hold) + scroll | AdvancedTerrainModifiers | Change tool hardness | Hoe / cultivator / shovel out |
| `O` | Server devcommands | Admin bundle: `debugmode` + `nocost` + `god` | Admins only |
| `K` | Server devcommands | Admin `fly` toggle | Admins only |

**Resolved conflicts (2026-09-11 audit):**

- **ExtraSlots shipped two duplicate binds against itself.** `Quickslot 5` and `Food 1` were both
  `Alt + Q`; `Quickslot 6` and `Food 3` were both `Alt + R`. The quickslots were moved to `Alt + U` /
  `Alt + Y` rather than the food slots, because `Alt + Q/E/R` keeps the food row a coherent set and
  `Alt + Z/X/C` preserves the muscle memory from the old pack's AzuExtendedPlayerInventory binds.
- **HUDCompass `Alt + C` collided with ExtraSlots `Quickslot 3`.** The compass moved to bare `J` --
  a documented free key -- since quickslot Z/X/C matches the old pack.
- **`Rebind Connect Panel` stays on `F2` -- an earlier audit pass wrongly moved it to `F6`.** That
  setting is ExtraSlots exposing the key for *vanilla's* Connect Panel (the F2 FPS / ping / ZDO HUD,
  which in 1.0 also shows the active world modifiers). Its `F2` default means "leave vanilla alone";
  there was no conflict. Moving it relocated the performance HUD, which players noticed as it having
  "disappeared". Do not re-flag this in future audits.
- All remaining ExtraSlots binds are `Alt`-modified, so none shadow a bare vanilla key. `Delete` and
  `J` are unclaimed in vanilla.
- **ExtraSlots quickslot 5/6 labels fixed (2026-09-14).** The binds had been moved to `Alt + U` /
  `Alt + Y` on 2026-09-11 but the on-slot label keys (`Quickslot 5 Text` / `Quickslot 6 Text`) still
  read "Alt + Q" / "Alt + R". Labels now match the binds.

**Building mods (2026-09-14 audit)** -- all binds are the old pack's already-resolved values, carried
forward unchanged:

- Gizmo `resetRotationKey` `V` -> `G` (V = vanilla voice chat); `resetAllRotationKey` `T`; `copyPieceRotation`
  left empty, `selectTargetPieceKey` `P`.
- ESPME Manual+ `LeftAlt` -> `B` (LeftAlt = Gizmo z-rotate + ATM radius scroll); grid snap `F3` -> `F11`
  (F3 was ConfigurationManager in the old pack -- kept on F11 anyway, F3 stays free). Iterate keys `Q` /
  `E` fire only inside manual snap modes -- accepted 2026-07-15, do not re-flag.
- Gizmo `Alt + scroll` vs ATM `Alt + scroll`: both in build mode, resolved by Gizmo
  `ignoreTerrainOpPrefab = true` -- terrain-op prefabs get no gizmo, so the scroll goes to ATM.
- Gizmo/ATM hold `LeftAlt` while ExtraSlots binds `Alt + <letter>` globally. They only collide if a
  quickslot / food / ammo letter is pressed *while* rotating or resizing -- same context-overlap class
  as the old pack. Accepted; if it bites in play, ExtraSlots' `Drag key` and chords are the ones to move.
- `LeftShift` (Gizmo x-rotate) and `LeftControl` (ATM hardness) are vanilla run/crouch, used here only
  as held scroll-modifiers in build mode -- same as the old pack.
- Newly claimed: `G`, `T`, `P`, `` ` ``, `PageUp`, `PageDown`, `B`, `CapsLock`, `F4`, `F11`. Free keys
  remaining for future mods: `U`(bare), `Y`(bare), `F3`, `F6`, `F7`, `F8`, `F10`.

Also tuned: CraftFromChests `SearchRadius` 40 -> 30, matching the old pack's AzuCraftyBoxes container
range rather than the mod's more generous default.

## Old pack -> new pack

| Dropped (no 1.0 build) | Replaced by |
|---|---|
| AzuAutoStore | `ServersideQoL_AutoStore` (server) |
| AzuContainerSizes | `ServersideQoL_ContainerSizes` (server) |
| AzuCraftyBoxes | Toxo-CraftFromChests |
| AzuExtendedPlayerInventory | shudnal-ExtraSlots |
| AzuHoverStats | MyLittleUI (tooltips) |
| AAA_Crafting | MyLittleUI (multicraft) |
| Recycle_N_Reclaim | *nothing* - see "RecyclePlus removed" |
| Quick Stack Store Sort Trash | RecyclePlus (trash) + `_AutoStore` (stacking) |
| AzuAreaRepair, AzuMiscPatches | nothing - dropped |
| MultiUserChest | nothing - only an unofficial rebuild exists |
| SleepSkip | `ServersideQoL_JustSleep` (server) |
| AutomaticFuel | `ServersideQoL_AutoProcess` (server) |
| Venture Floating Items | `ServersideQoL_LetItFloat` (server) |
| NetworkTweaks, TimeoutLimit | `ServersideQoL_MultiplayerTweaks` (server) |
| TeleportEverything | vanilla `-modifier portals casual` - no mod needed |
| Gizmo, ExtraSnapPointsMadeEasy | same mods, 1.0 builds (2026-09-14) |
| AdvancedTerrainModifiers | Ostrix-AdvancedTerrainModifiersCompatible fork (2026-09-14) |

## What you lose, honestly

Building: **Gizmo, ExtraSnapPointsMadeEasy and AdvancedTerrainModifiers are back** as of 2026-09-14
(see "Building mods"). Still gone: **AzuAreaRepair** (no 1.0 build) and **MissingPieces** (has a 1.0
build, but it writes custom prefabs into the world, so removing it later leaves holes in builds).

Also dropped: ProjectileTweaks, ShieldBash, SmartSkills, Seasons, TargetPortal, SpeedyPaths,
StumpsAreOneHp, LocalizationCache, AdventureBackpacks, Groups, VNEI, ConfigurationManager,
PlantEverything/PlantEasily/MassFarming.

## Verified 1.0-ready, available as one-line adds

Left out to keep the count down, but all confirmed updated:

```
Advize-PlantEverything      = "1.21.1"   # plant every resource
Advize-PlantEasily          = "2.2.0"    # grid planting
Crystal-DigDeeper           = "1.3.0"    # deeper digging
shudnal-ConfigurationManager = "1.1.18"  # in-game config editor (+ JsonDotNET)
MSchmoecker-VNEI            = "0.17.6"   # item browser (pulls in Jotunn)
ArgusMagnus-ServersideQoL_ContainerSigns = "2.0.4"   # chest labels
ArgusMagnus-ServersideQoL_PortalProgression = "2.0.0" # ores by boss progress
```

`_PortalProgression` is worth a look: progressively more ores through portals as bosses fall. Closer to
this pack's original "no teleport-cheese" rule than the blunt `portals casual` modifier - but pick one,
since `portals casual` sets the `teleportall` global key and makes the mod moot.

## Deploying

```bash
make profile                 # client -> dist/Fimbulwinter_Lite-v2.0.0-profile.r2z
bash scripts/deploy.sh full  # server (.env SERVER_ID must point at the right instance)
```

## Test results (2026-09-11)

Both sides booted and verified live. **The four building packages added 2026-09-14 are not covered by
this section yet** -- see "Building mods" for the pending test order.

**Server** (14 packages - the 17 minus the 3 client-only): 13/13 plugins loaded, 0 NullReference,
0 MissingMethod, world reached `Opened Steam server` / `Game server connected`. ServersideQoL reports
`Enabled: True`. The only `[Error]` lines are vanilla headless-graphics noise (video decode shaders,
intro cinematic) - expected under `-nographics -batchmode`, present on a stock server too.

**Client** (10 packages): 9/9 plugins loaded, 0 NullReference, 0 MissingMethod, 0 errors, main menu
reached, and the **Settings menu opens clean** - the exact failure that Smoothbrain-Groups caused.

**One real bug found and fixed by testing:** the egg allowed `normal` as a `-modifier` value. The game
rejects it (`Could not parse 'deathpenalty' with a value of 'normal' as a world modifier`) - for
modifiers, normal is expressed by *omission*. Removed from the validation rules for all five
modifiers; `-preset normal` remains valid and is unaffected.

Note: RecyclePlus reports its internal version as 1.3.1 while the Thunderstore package is 1.3.2 - the
author did not bump the assembly string. Cosmetic.
