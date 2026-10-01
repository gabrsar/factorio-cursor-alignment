# Contributing

Keep changes focused and document the resulting user behavior. Repository documentation is in English; localized game strings belong in `src/locale/`.

## Before submitting

- Run `python3 tools/build.py check` and the packaging regression suite from `DEVELOPMENT.md`.
- For runtime changes, run `test`; for GUI/input changes, also run `test-client`.
- State what was actually verified. Mark untested platforms or multiplayer as unverified.
- For a release, update metadata and changelog together.
- Do not commit generated packages, test artifacts, installation backups or credentials.
- Preserve saved references during configuration and appearance changes.

## Translations

Update English first, then add matching keys to all locales. Preserve `__CONTROL__...__` tokens so remapped shortcuts display correctly. Keep visible text short; use tooltips for longer explanations. Native-speaker corrections are welcome.

## Bugs

Include Factorio/mod versions, OS, relevant mods, reproduction steps and the error section of `factorio-current.log`. Redact personal details. Screenshots help with layout problems; do not attach a full save unless needed for reproduction.
