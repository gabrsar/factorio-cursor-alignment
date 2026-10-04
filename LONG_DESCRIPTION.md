# Cursor Alignment

One-tile-wide translucent alignment guides for **Factorio 2.1**. Align belts, buildings and selections using the live cursor or persistent colored references. **Space Age is not required.**

## See your alignment at a glance

Horizontal and vertical guide bands help you line up distant belts and buildings without hiding the factory underneath. Ordinary buildings follow the snapped build cursor; copy, selection and blueprint tools follow the free cursor.

## Keep multiple colored references

Click the alignment button in the game's shortcut bar or press **Control + Shift + S** to equip the alignment tool. Click a tile to add a fixed pair of guides. Each reference receives its own color, with a contrasting border and center dot marking its root tile. Enable the button in the shortcut bar's selection menu if it is hidden.

The tool stays active across repeated clicks. Click **a marked root tile** again to remove that reference. Exit with **Q** (clear cursor), **Escape** or **right click**. Dragging a selection toggles one reference at its center, snapped to a tile.

References stay saved when you change tools, switch surfaces or reload your game. Exiting the tool does not remove them. Toggling visibility hides references temporarily; it does not delete them.

## Make the guides yours

Open the settings panel using the top-left button or its shortcut. Changes apply immediately and are saved per player.

- Choose between **while building/selecting**, **manual toggle** and **always visible** using three visible radio options.
- Adjust the guide reach and optionally show only snapped guides.
- Choose the live guide color using RGB controls. Fixed references retain their individual colors.
- Adjust opacity, fill intensity and additive color mixing to keep the world readable.

## Shortcuts

| Action | Primary default | macOS alternative |
| --- | --- | --- |
| Open settings | Control + Shift + O | Command + Shift + O |
| Toggle visibility | Control + Shift + H | Command + Shift + H |
| Equip alignment tool | Control + Shift + S | Command + Shift + S |

**All shortcuts are customizable in Settings → Controls.** Search for Cursor Alignment or the localized action names. The panel displays your current bindings. Existing custom bindings are preserved when upgrading; assign the Command alternative manually if it is absent.

## Compatibility and current limits

- Requires **Factorio 2.1**; no expansion or other mod is required.
- These are visual guides: they do not change placement or create world entities.
- Fixed reference tiles are snapped to the grid. Continuous snapping for blueprints, copy/selection tools, tile painting and off-grid placement is not implemented.
- Hold-Shift activation is not implemented; manual visibility uses a toggle.
- Hovering an entity with an empty hand does not automatically create a reference. Use the shortcut.
- Gameplay and the settings panel have been tested on Windows with Factorio 2.1.20. Native macOS/Linux gameplay and multiplayer have not yet been verified. Command alternatives use Factorio's supported modifier system, but have not been physically tested on a Mac.

## Languages

English, Brazilian Portuguese, Spanish, French, German, Italian, Russian, Simplified Chinese, Japanese and Korean.

## Source and feedback

[Source code and documentation](https://github.com/gabrsar/factorio-cursor-alignment) · [Report a bug](https://github.com/gabrsar/factorio-cursor-alignment/issues)

When reporting a bug, include the Factorio and mod versions, your platform, steps to reproduce and the relevant error from `factorio-current.log`.

Released under the **MIT license**.
