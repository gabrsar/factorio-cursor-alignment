# Cursor Alignment

Translucent one-tile-wide alignment guides for Factorio 2.1. No Space Age requirement.

- Control+Shift+O: open settings.
- Control+Shift+H: toggle visibility.
- Control+Shift+S or the shortcut-bar alignment button: equip the alignment tool. Click tiles to add/remove references. Exit with Q (clear cursor), Escape or right click.

Command+Shift alternatives are provided for macOS. Customize all bindings in Factorio's controls. The panel shows your configured bindings.

Multiple references have distinct colors and marked root tiles. Remove one by clicking its marked tile with the alignment tool. The tool stays active after each click; exiting preserves references. References persist across tool changes, surface travel and save/load. Resetting appearance preserves them.

RGB affects live guides. Opacity and mixing apply to bands; root markers stay visible. Contextual, manual-toggle and always-visible modes are mutually exclusive.

Hold-Shift activation and continuous copy/selection snapping are not implemented. Fixed references are stationary.

Documentation and bugs: https://github.com/gabrsar/factorio-cursor-alignment

MIT license. Python/Make are only for building from source, not playing with this mod.

Drag a selection to add references at its two opposite corner tiles. Existing corner references are preserved. A single-tile selection toggles one reference.

Use **Clear all references** in the settings panel (Control + Shift + O) to remove all your fixed references across every surface at once. Live guides, appearance settings and other players' references are preserved.
