# Fimbulwinter Minimal - server-side-first QoL for Valheim 1.0

**Branch: `lite-minimal`. Temporary, local-only. Never pushed to `main`, never tagged, never published.**

A ground-up rebuild of the pack for Valheim 1.0 "Deep North", built on two rules:

1. **Zero Azumatt mods.** None of the nine in the old pack have shipped a 1.0 build.
2. **If the server can do it, the server does it.** Players install as little as possible.

**17 packages, down from 58.** Every package verified against the Thunderstore API as published
on/after 2026-09-09 (Valheim 1.0.0) - except the two pure serialization libraries, which contain no
game code. **No Jotunn anywhere in the dependency graph.**

## The split

Only 10 packages reach players. The other 7 live on the dedicated server and are excluded from the
client profile automatically (`SERVER_ONLY_MODS` in `scripts/export-profile.sh`).

### Client (10) - `make profile`

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

## NOT YET TESTED

Nothing here has been booted. Selection was made from Thunderstore metadata - publish dates,
dependency graphs, deprecation flags - not from running the game. That is *not* sufficient on its own:
during the 1.0 investigation both ComfyMods-Gizmo and Smoothbrain-Groups loaded perfectly cleanly and
still broke the main menu and the Settings screen respectively, with no trace in their own stack traces.
Boot-test with the enable-list + Settings-click harness before putting this in front of anyone.
