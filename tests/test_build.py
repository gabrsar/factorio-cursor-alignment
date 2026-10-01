"""Packaging and install regressions; no Factorio installation required."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch
import zipfile
from tools import build as tool


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        source = root / 'src'
        shutil.copytree(tool.SRC, source)
        package = root / 'dist' / f'{tool.NAME}.zip'
        overrides = patch.multiple(tool, ROOT=root, SRC=source, WORK=root / 'work', DIST=root / 'dist', PACKAGE=package)
        overrides.start()
        self.addCleanup(overrides.stop)

    def test_reproducible_release_and_checksum(self):
        tool.build()
        original = tool.PACKAGE.read_bytes()
        for path in tool.SRC.rglob('*.lua'):
            path.write_bytes(path.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n'))
        tool.build()
        self.assertEqual(original, tool.PACKAGE.read_bytes())
        self.assertTrue(tool.PACKAGE.with_suffix('.zip.sha256').read_text().startswith(hashlib.sha256(original).hexdigest()))
        with zipfile.ZipFile(tool.PACKAGE) as archive:
            self.assertIsNone(archive.testzip())
            self.assertIn(f'{tool.NAME}/info.json', archive.namelist())
            self.assertFalse(any('/tests/' in name or '/work/' in name for name in archive.namelist()))

    def test_validation_rejects_invalid_thumbnail_and_control_tokens(self):
        image = tool.SRC / 'thumbnail.png'
        original = image.read_bytes()
        image.write_bytes(b'not a PNG')
        with self.assertRaises(ValueError):
            tool.check()
        image.write_bytes(original)
        locale = tool.SRC / 'locale/pt-BR/locale.cfg'
        locale.write_text(locale.read_text(encoding='utf-8').replace('__CONTROL__cursor-alignment-toggle__', '__CONTROL__wrong__'), encoding='utf-8')
        with self.assertRaises(ValueError):
            tool.check()

    def test_install_preserves_other_mods_settings_and_backs_up(self):
        tool.build()
        folder = tool.ROOT / 'mods'
        folder.mkdir()
        listing = folder / 'mod-list.json'
        listing.write_text(json.dumps({'mods':[{'name':'other','enabled':False}]}))
        settings = folder / 'mod-settings.dat'
        settings.write_bytes(b'leave preferences alone')
        (folder / tool.PACKAGE.name).write_bytes(b'previous package')
        with patch.object(tool, 'test'):
            tool.install(argparse.Namespace(mod_dir=str(folder)))
        entries = json.loads(listing.read_text())['mods']
        self.assertIn({'name':'other','enabled':False}, entries)
        self.assertIn({'name':tool.INFO['name'],'enabled':True}, entries)
        self.assertEqual(settings.read_bytes(), b'leave preferences alone')
        backup = next((tool.ROOT / 'backups').iterdir())
        self.assertEqual((backup / tool.PACKAGE.name).read_bytes(), b'previous package')
        tool.WORK.mkdir()
        (tool.WORK / 'generated.txt').write_text('temporary')
        tool.clean()
        self.assertTrue(settings.exists())
        self.assertTrue(backup.exists())
        self.assertTrue(tool.SRC.exists())


if __name__ == '__main__':
    unittest.main()
