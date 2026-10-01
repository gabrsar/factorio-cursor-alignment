# Cursor Alignment

![Cursor Alignment](src/thumbnail.png)

Translucent row and column guides for **Factorio 2.1**. Each band is one tile wide. No Space Age dependency.

## Controls

| Action | Default binding |
|---|---|
| Settings panel | Ctrl+Shift+O, or the top-left button |
| Toggle guides | Ctrl+Shift+H |
| Highlight hovered entity / toggle fixed tile reference | Ctrl+Shift+S |

Bindings can be changed in Factorio's controls. Building, ghosts, copy/cut/paste, blueprints and selection tools activate guides automatically in contextual mode. Empty-hand hover does not automatically activate them.

## Appearance

The panel applies changes immediately and stores them per player: RGB color, color alpha, fill intensity, additive color mix, reach, contextual/manual/always visibility, and an optional grid-only filter. Options are also in the standard mod settings.

Normal blending adds a transparent tint. Increasing additive mix retains more background brightness. Default opacity is approximately 16% per band; their intersection is slightly stronger.

Languages: English, Brazilian Portuguese, Spanish, French, German, Italian, Russian, Simplified Chinese, Japanese and Korean. Translation keys are validated; native-speaker improvements are welcome.

**Ctrl+Shift+S** adds or removes a fixed reference on the cursor tile. You can keep multiple references. Each stays until you press the shortcut again on its own tile and surface. References survive tool changes, deselection, surface travel and saving/loading. Visibility toggles hide them temporarily; resetting appearance does not delete them. Live cursor guides remain available alongside the fixed references.

## API limitations

- Ordinary buildable entities use the game's snapped build cursor. Even-sized entities receive a half-tile correction to cover a full tile.
- Fixed references snap the key event cursor position to a tile, including negative coordinates. They stay at that position.
- Copy/selection tools, blueprints, tile painting and off-grid/diagonal entities still follow the free cursor. Factorio exposes a local render target, not continuously readable mouse coordinates; Lua cannot apply floor or modulo to that target. **Continuous grid stepping for these tools is not implemented.** Grid-only mode hides unsnapped bands.
- **Hold Shift modes are not implemented.** Factorio 2.1 exposes key activation, but neither key release nor held-key state. Manual mode is a toggle, not a hold detector.

References: [render targets](https://lua-api.factorio.com/latest/concepts/ScriptRenderTargetTable.html), [custom inputs](https://lua-api.factorio.com/latest/prototypes/CustomInputPrototype.html), [held-input API request](https://forums.factorio.com/viewtopic.php?t=103051).

## Install

Build the ZIP, place it in `%APPDATA%\Factorio\mods` without extracting, enable it and restart Factorio. Alternatively use `make install`. This repository is not a Mod Portal publication.

## Development on Windows

Edit `src/`. Requires Windows PowerShell 5.1+; tests require an installed Factorio 2.1. No Python dependency.

| Target | Action |
|---|---|
| `make build` / `make compile` | Validate locales and package `dist/cursor-alignment_<version>.zip`. Lua needs no compilation. |
| `make test` / `make check` | Build, load the release ZIP headlessly, run behavior tests. |
| `make test-client` | Run real GUI/settings/rendering tests in an isolated graphical benchmark and save a panel screenshot. |
| `make install` | Test, copy to mods, enable the mod, back up replaced files. |
| `make clean` | Delete generated test files and current ZIP; preserve source, backups and installed mods. |
| `make rebuild` | Clean, build and test. |
| `make doctor` | Check paths and game version. |

Without GNU Make:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 test
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1 install
```

Override default paths using `FACTORIO_EXE` and `FACTORIO_MOD_DIR`, or pass `-Factorio` and `-ModDirectory`. Close the game before installing, then restart. Backups are in `backups/`, preserved by `clean`.

Tests use temporary maps in `work/`, never user saves. They cover engine loading, real inventories/prototypes/render objects, snapping targets and parity, negative coordinates, hover gating, manual/always modes, opacity/mix, surface changes and recovery. Behavior tests use a synthetic player. The native client test covers actual GUI creation and settings writes; physical input and multiplayer still require in-game validation. Logs: `work/release-load.log` and `work/behavior.log`.

## Português

**Ctrl+Shift+S** adiciona/remove uma referência no tile do cursor. Você pode manter várias e remover cada uma no próprio tile. A referência é fixa, sem acompanhamento contínuo. Abra o painel pelo botão no canto superior esquerdo ou **Ctrl+Shift+O**. Ajuste cor, opacidade, mistura aditiva e alcance. **Ctrl+Shift+H** alterna as guias e **Ctrl+Shift+S** destaca a entidade sob o cursor. O modo manual usa alternância: segurar Shift e encaixe contínuo ao copiar/selecionar ainda não são suportados pela API.

MIT license. See [asset provenance](ASSETS.md) for the icon.
