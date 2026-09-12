# Fimbulwinter Lite 2.0.0 - server-side-first QoL for Valheim 1.0

**Branch: `lite-minimal`. Temporary, local-only. Never pushed to `main`, never tagged, never published.**

A ground-up rebuild of the pack for Valheim 1.0 "Deep North", built on two rules:

1. **Zero Azumatt mods.** None of the nine in the old pack have shipped a 1.0 build.
2. **If the server can do it, the server does it.** Players install as little as possible.

**19 packages, down from 58.** Every package verified against the Thunderstore API as published
on/after 2026-09-09 (Valheim 1.0.0) - except the two pure serialization libraries, which contain no
game code. **No Jotunn anywhere in the dependency graph.**

## The split

Only 12 packages reach players. The other 7 live on the dedicated server and are excluded from the
client profile automatically (`SERVER_ONLY_MODS` in `scripts/export-profile.sh`).

### Client (12) - `make profile`

| Package | Version | Role |
|---|---|---|
| denikson-BepInExPack_Valheim | 5.4.2350 | loader |
| ValheimModding-YamlDotNet | 16.3.1 | library |
| shudnal-ConditionalConfigSync | 1.0.5 | server-enforced config |
| **shudnal-MyLittleUI** | 1.2.18 | tooltips, production timers, chest preview, multicraft, weather |
| **shudnal-ExtraSlots** | 1.2.3 | equipment + quick slots |
| **Toxo-CraftFromChests** | 0.4.0 | craft/build/fuel from nearby chests |
| **Neobotics-HUDCompass** | 1.2.0 | compass bar |
| **JoelOliMclean-NoRainDamage** | 1.3.0 | no weather decay on builds |
| **korCaptain-NullReferenceFix** | 1.0.20 | stability |
| **JereKuusela-Server_devcommands** | 1.112.0 | admin console on a dedicated server (see below) |
| **Crystal-DeathPenalty** | 1.3.0 | tunes skill loss on death -- replaces SmartSkills |
| **cjayride-RecycleItemsIntoParts** | 1.7.3 | recycle items into parts (drag + `Delete`) -- see caveat |

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

Audited 2026-09-11 against the mods' freshly generated configs. MyLittleUI, CraftFromChests,
NoRainDamage and NullReferenceFix declare **no** keybinds at all, so the entire bind surface is below.

| Key | Mod | Action | Context |
|-----|-----|--------|---------|
| `Alt + Z / X / C / V` | ExtraSlots | Quick slots 1-4 | Anywhere |
| `Alt + U` | ExtraSlots | Quick slot 5 | Anywhere (moved off `Alt + Q`, see below) |
| `Alt + Y` | ExtraSlots | Quick slot 6 | Anywhere (moved off `Alt + R`, see below) |
| `Alt + 1 / 2 / 3` | ExtraSlots | Ammo slots 1-3 | Anywhere |
| `Alt + Q / E / R` | ExtraSlots | Food slots 1-3 | Anywhere |
| `Alt` (hold) | ExtraSlots | Drag item between equipment slots | Inventory open |
| `F6` | ExtraSlots | Connect-panel rebind | Anywhere (moved off `F2`, see below) |
| `J` | HUDCompass | Toggle the compass bar | Anywhere (moved off `Alt + C`, see below) |
| `O` | Server devcommands | Admin bundle: `debugmode` + `nocost` + `god` | Admins only |
| `K` | Server devcommands | Admin `fly` toggle | Admins only |

**Resolved conflicts (2026-09-11 audit):**

- **ExtraSlots shipped two duplicate binds against itself.** `Quickslot 5` and `Food 1` were both
  `Alt + Q`; `Quickslot 6` and `Food 3` were both `Alt + R`. The quickslots were moved to `Alt + U` /
  `Alt + Y` rather than the food slots, because `Alt + Q/E/R` keeps the food row a coherent set and
  `Alt + Z/X/C` preserves the muscle memory from the old pack's AzuExtendedPlayerInventory binds.
- **HUDCompass `Alt + C` collided with ExtraSlots `Quickslot 3`.** The compass moved to bare `J` --
  a documented free key -- since quickslot Z/X/C matches the old pack.
- **ExtraSlots `Rebind Connect Panel` was on `F2`**, which Valheim 1.0 uses to display the active
  world modifiers. Moved to `F6` (free now that AutomaticFuel is gone).
- All remaining ExtraSlots binds are `Alt`-modified, so none shadow a bare vanilla key. `Delete` and
  `J` are unclaimed in vanilla. Free keys remaining for future mods: `U`(bare), `Y`(bare), `F4`, `F7`,
  `F8`, `F10`, `F11`.

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

## What you lose, honestly

Building goes back to vanilla: **Gizmo, ExtraSnapPointsMadeEasy, AzuAreaRepair, AdvancedTerrainModifiers,
MissingPieces** are all gone (only MissingPieces has a 1.0 build, and it writes custom prefabs into the
world, so removing it later leaves holes in builds).

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

Both sides booted and verified live.

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
