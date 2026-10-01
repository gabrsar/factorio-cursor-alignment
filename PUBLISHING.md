# Publishing a release

GitHub hosts the source. Publish the packaged mod on the [Factorio Mod Portal](https://mods.factorio.com/) to make it available through the in-game mod manager.

## Release checklist

1. Update `src/info.json` and add the matching version at the top of `src/changelog.txt`.
2. Run validation and packaging regressions:

   ```sh
   python3 tools/build.py check
   python3 -m unittest discover -s tests -p test_build.py -v
   ```

3. Run `python3 tools/build.py test` and `python3 tools/build.py test-client` with an installed Factorio 2.1.
4. Inspect screenshots and manually test remapped inputs, rotations, blueprint operations and saved references in a disposable map. Test an actual platform/multiplayer session before claiming it was verified.
5. Run `python3 tools/build.py build`. Upload `dist/cursor-alignment_<version>.zip`, **without extracting it**. It contains the matching versioned folder, metadata, Lua, translations, license, changelog and 144×144 icon.
6. Commit/tag the tested source. Optionally attach the ZIP and `.zip.sha256` to a GitHub release. A tag does not automatically create a release.

The checksum sidecar is for download verification, not portal upload. CI validates packaging but does not run the game or automatically publish.

## Portal account and upload

Use a Factorio.com account with a purchased copy. Steam purchasers can link their account in the [Factorio profile](https://www.factorio.com/profile). See the [official terms](https://www.factorio.com/terms-of-service).

For initial publication, choose **Submit mod**, upload the ZIP and complete the listing. The technical name must be available. For updates, upload a new version to the existing listing.

Suggested listing: **Cursor Alignment**, **Utilities** category, **MIT** license, and source URL <https://github.com/gabrsar/factorio-cursor-alignment>. Describe live guides, colored persistent references, configurable shortcuts and current limitations. Include screenshots of the markers and settings panel.

Do not advertise hold-Shift activation, continuous selection/copy snapping, or platform tests that were not performed. Verify the uploaded version through the in-game manager on a disposable setup.

## Optional automation

The [Mod Publish API](https://wiki.factorio.com/Mod_publish_API) uses a profile key with **ModPortal: Publish Mods** permission. Store it outside the repository, such as in a GitHub secret. Website uploads do not need an API key. This repository does not include an automatic portal uploader.

Package requirements: [official mod structure](https://lua-api.factorio.com/latest/auxiliary/mod-structure.html).
