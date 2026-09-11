# Fimbulwinter Vanilla - Valheim 1.0.0 + BepInEx (no mods)

**Branch: `vanilla`. Temporary, local-only bootstrap. Never pushed to `main`, never tagged, never published to Thunderstore.**

Valheim 1.0.0 "Deep North" (2026-09-09) broke a large share of the modding ecosystem. Rather than
wait for every mod to catch up, this branch strips the pack down to the one thing that has already
shipped a 1.0-compatible build: **BepInEx itself**. The loader is installed and ready, the plugin
folder is empty, and mods get layered back on one at a time as their authors ship 1.0 updates.

| | |
|---|---|
| Mods | 0 |
| Loader | BepInExPack_Valheim 5.4.2350 |
| Target game version | Valheim 1.0.0 or newer (the 1.0 "Deep North" line) |
| Client profile | `Fimbulwinter-Vanilla-v1.0.0` (via `make profile`) |
| Server egg | `server/valheim-fimbulwinter-lite-egg.yaml` |

## Client setup

```bash
make profile          # -> dist/Fimbulwinter_Vanilla-v1.0.0-profile.r2z
```

Import it in r2modman: **Profiles -> Import / Update -> From file**. It installs BepInEx and the one
shipped config file, and lands as a profile named `Fimbulwinter-Vanilla-v1.0.0` so it never collides
with the modded profiles.

**No BepInEx console window.** `config/BepInEx.cfg` ships with `[Logging.Console] Enabled = false`,
`PreventClose = false` and `ForceBepInExTTYDriver = false`. Under Valheim 1.0's Unity 6 engine the
forced TTY console renders as a non-closable overlay that steals all mouse and keyboard input, so all
three stay off here. Disk logging (`BepInEx/LogOutput.log`) is untouched and remains how to debug.

## Server setup

Import `server/valheim-fimbulwinter-lite-egg.yaml` into the Pelican panel as a **new egg** (it carries
its own UUID, so it sits alongside the modded Fimbulwinter Lite egg rather than replacing it), then
create or reinstall a server on it.

The egg is **fully self-contained** - unlike the modded egg it fetches no scripts from GitHub, because
this branch is local-only and a remote bootstrap would 404. It installs Valheim via SteamCMD, drops in
BepInEx, and purges `BepInEx/plugins` + `BepInEx/patchers` so the result is guaranteed mod-free even
when reinstalling over a previously modded server.

### World modifiers

Every Valheim world modifier is its own panel field. Leave a field **empty** to get the vanilla
default for that dial.

| Panel field | Variable | Accepted values |
|---|---|---|
| World Preset | `PRESET` | `normal` `casual` `easy` `hard` `hardcore` `immersive` `hammer` |
| Modifier: Combat | `MODIFIER_COMBAT` | `veryeasy` `easy` `normal` `hard` `veryhard` |
| Modifier: Death Penalty | `MODIFIER_DEATHPENALTY` | `casual` `veryeasy` `easy` `normal` `hard` `hardcore` |
| Modifier: Resources | `MODIFIER_RESOURCES` | `muchless` `less` `normal` `more` `muchmore` `most` |
| Modifier: Raids | `MODIFIER_RAIDS` | `none` `muchless` `less` `normal` `more` `muchmore` |
| Modifier: Portals | `MODIFIER_PORTALS` | `casual` `normal` `hard` (no boss portals) `veryhard` (no portals) |
| Key: No Build Cost | `KEY_NOBUILDCOST` | 0 / 1 |
| Key: Player Events | `KEY_PLAYEREVENTS` | 0 / 1 |
| Key: Passive Mobs | `KEY_PASSIVEMOBS` | 0 / 1 |
| Key: No Map | `KEY_NOMAP` | 0 / 1 |
| Extra Setkeys | `EXTRA_SETKEYS` | space-separated, for keys Iron Gate adds later |

**Argument order is handled for you.** A `-preset` placed *after* `-modifier` flags silently
overwrites them, so the startup command always emits `-preset` first, then the five modifiers, then
the setkeys, then `-instanceid`/`-crossplay`, and finally `EXTRA_ARGS` (which can therefore override
anything). The assembled line is echoed to the panel console on every boot as `[STARTUP] World args:`.

### Other server variables

| Variable | Default | Notes |
|---|---|---|
| `BEPINEX_ENABLED` | 1 | Set 0 to run 100% pure vanilla without reinstalling - doorstop simply is not injected |
| `BEPINEX_VERSION` | `latest` | Resolved from Thunderstore at install time, or pin e.g. `5.4.2350` |
| `PURGE_PLUGINS` | 1 | Wipe plugins/patchers on install so a reinstall over a modded server is truly clean |
| `ADMIN_STEAMIDS` | empty | Space-separated Steam64 IDs written to `adminlist.txt` each boot (overwrites it) |
| `SAVE_DIR` | `/home/container/saves` | Matches the existing server, so the current world is found as-is |
| `INSTANCE_ID` | empty | `-instanceid`, for telling multiple servers on one host apart |
| `EXTRA_ARGS` | empty | Raw passthrough, appended last |
| `SAVE_INTERVAL` / `BACKUP_COUNT` / `BACKUP_SHORTTIME` / `BACKUP_LONGTIME` | 1800 / 4 / 7200 / 43200 | `-saveinterval` / `-backups` / `-backupshort` / `-backuplong` |

### Changing modifiers on a live world

Set `ADMIN_STEAMIDS` so you get the F5 console with `devcommands` enabled:

```
setworldmodifier <name> <value>     e.g. setworldmodifier portals casual
setkey <key> / removekey <key>      e.g. setkey nomap
```

Press **F2** in game at any time to see which modifiers are actually active on the server.

## When mods come back

Nothing here is load-bearing for the modded pack - `main` and `2.0.0-rc` still hold the real thing.
When authors ship 1.0-compatible builds, the first things to add back are the pure libraries, which
carry no gameplay behaviour of their own:

| Library | Version | 1.0 status |
|---|---|---|
| `ValheimModding-Jotunn` | 2.30.0 | updated 2026-09-09 (adds a client/server version check - expect join-time mismatch popups if only one side has it) |
| `ValheimModding-JsonDotNET` | 13.0.4 | inert until a consumer needs it |
| `ValheimModding-YamlDotNet` | 16.3.1 | inert until a consumer needs it |
| `shudnal-ConditionalConfigSync` | 1.0.5 | updated 2026-09-10 |
| `shudnal-ConfigurationManager` | 1.1.18 | updated 2026-09-11, needs the two DotNET libraries |

They are deliberately **not** shipped here: with zero consumers they add zero value and only widen the
surface area of a baseline whose whole purpose is to be provably clean. Add them in the same commit as
the first mod that actually needs them.

## Ground rules for this branch

- Do not merge into `main`, do not tag, do not publish to Thunderstore.
- The egg has **no `update_url`** on purpose - pointing it at `main` would let the panel silently
  "update" this vanilla egg into the modded one.
- `versionNumber = "1.0.0"` tracks the targeted Valheim release line, not a pack release number. SteamCMD always installs whatever is current on the stable branch.
