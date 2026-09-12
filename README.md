# Fimbulwinter Minimal - server-side-first QoL for Valheim 1.0

**Branch: `lite-minimal`. Temporary, local-only. Never pushed to `main`, never tagged, never published.**

A ground-up rebuild of the pack for Valheim 1.0 "Deep North", built on two rules:

1. **Zero Azumatt mods.** None of the nine in the old pack have shipped a 1.0 build.
2. **If the server can do it, the server does it.** Players install as little as possible.

**18 packages, down from 58.** Every package verified against the Thunderstore API as published
on/after 2026-09-09 (Valheim 1.0.0) - except the two pure serialization libraries, which contain no
game code. **No Jotunn anywhere in the dependency graph.**

## The split

Only 11 packages reach players. The other 7 live on the dedicated server and are excluded from the
client profile automatically (`SERVER_ONLY_MODS` in `scripts/export-profile.sh`).

### Client (11) - `make profile`

| Package | Version | Role |
|---|---|---|
| denikson-BepInExPack_Valheim | 5.4.2350 | loader |
| ValheimModding-YamlDotNet | 16.3.1 | library |
| shudnal-ConditionalConfigSync | 1.0.5 | server-enforced config |
| **shudnal-MyLittleUI** | 1.2.18 | tooltips, production timers, chest preview, multicraft, weather |
| **shudnal-ExtraSlots** | 1.2.3 | equipment + quick slots |
| **Toxo-CraftFromChests** | 0.4.0 | craft/build/fuel from nearby chests |
| **TastyChickenLegs-RecyclePlus** | 1.3.2 | recycle + trash |
| **Neobotics-HUDCompass** | 1.2.0 | compass bar |
| **JoelOliMclean-NoRainDamage** | 1.3.0 | no weather decay on builds |
| **korCaptain-NullReferenceFix** | 1.0.20 | stability |
| **JereKuusela-Server_devcommands** | 1.112.0 | admin console on a dedicated server (see below) |

### Server only (7) - players install none of these

| Module | Version | Replaces |
|---|---|---|
| ArgusMagnus-ServersideQoL | 2.0.6 | (suite core) |
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
| `Delete` | RecyclePlus | Discard / recycle hovered item | Inventory |
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
| Recycle_N_Reclaim | TastyChickenLegs-RecyclePlus |
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
make profile                 # client -> dist/Fimbulwinter_Minimal-v3.0.0-profile.r2z
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
