#!/usr/bin/env python3
"""Portable, standard-library-only packaging and isolated Factorio checks."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SRC, WORK, DIST = ROOT / 'src', ROOT / 'work', ROOT / 'dist'
INFO = json.loads((SRC / 'info.json').read_text(encoding='utf-8'))
NAME = f"{INFO['name']}_{INFO['version']}"
PACKAGE = DIST / f'{NAME}.zip'


def locale(path):
    result, section = {}, ''
    for line in path.read_text(encoding='utf-8').splitlines():
        if line.startswith('[') and line.endswith(']'):
            section = line[1:-1]
        elif '=' in line and not line.startswith(';'):
            key, value = line.split('=', 1)
            key = section + '.' + key
            if key in result or not value.strip():
                raise ValueError(f'Duplicate/empty translation: {path}: {key}')
            result[key] = value
    return result


def check():
    if not re.fullmatch(r'[A-Za-z0-9_-]+', INFO['name']) or not re.fullmatch(r'\d+\.\d+\.\d+', INFO['version']):
        raise ValueError('Invalid mod name/version')
    for name in ('info.json', 'control.lua', 'panel.lua', 'settings.lua', 'data.lua', 'LICENSE', 'changelog.txt'):
        if not (SRC / name).is_file():
            raise ValueError(f'Missing source: {name}')
    english = locale(SRC / 'locale/en/locale.cfg')
    for path in sorted((SRC / 'locale').glob('*/locale.cfg')):
        values = locale(path)
        if values.keys() != english.keys():
            raise ValueError(f'Translation keys differ: {path}')
        for key, value in values.items():
            if sorted(re.findall(r'__CONTROL__[^\s.]+?__', value)) != sorted(re.findall(r'__CONTROL__[^\s.]+?__', english[key])):
                raise ValueError(f'Control placeholders differ: {path}: {key}')
    png = (SRC / 'thumbnail.png').read_bytes()
    if len(png) < 24 or png[:8] != b'\x89PNG\r\n\x1a\n' or png[12:16] != b'IHDR' or struct.unpack('>II', png[16:24]) != (144, 144):
        raise ValueError('thumbnail.png must be a 144x144 PNG')
    changelog = (SRC / 'changelog.txt').read_text(encoding='utf-8')
    version = re.search(r'^Version: (.+)$', changelog, re.M)
    if not version or version.group(1) != INFO['version']:
        raise ValueError('Changelog version must match info.json')
    print('PASS: metadata, changelog, thumbnail, translations and control placeholders')


def build():
    check()
    DIST.mkdir(exist_ok=True)
    temporary = PACKAGE.with_suffix('.zip.tmp')
    with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(SRC.rglob('*')):
            if not path.is_file():
                continue
            entry = zipfile.ZipInfo(f'{NAME}/{path.relative_to(SRC).as_posix()}', (2000, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.external_attr = 0o100644 << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            data = path.read_bytes()
            if path.suffix in ('.lua', '.json', '.cfg', '.md', '.txt') or path.name == 'LICENSE':
                data = data.replace(b'\r\n', b'\n')
            archive.writestr(entry, data, compresslevel=9)
    os.replace(temporary, PACKAGE)
    digest = hashlib.sha256(PACKAGE.read_bytes()).hexdigest()
    PACKAGE.with_suffix('.zip.sha256').write_text(f'{digest}  {PACKAGE.name}\n', encoding='utf-8')
    print(f'Built: {PACKAGE}')


def executable(args):
    configured = args.factorio or os.environ.get('FACTORIO_EXE')
    if configured:
        path = Path(configured).expanduser().resolve()
    elif shutil.which('factorio'):
        path = Path(shutil.which('factorio')).resolve()
    else:
        candidates = [Path(os.environ.get('ProgramFiles(x86)', 'C:/Program Files (x86)')) / 'Steam/steamapps/common/Factorio/bin/x64/factorio.exe'] if os.name == 'nt' else [
            Path('/Applications/factorio.app/Contents/MacOS/factorio'),
            Path.home() / 'Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio',
            Path.home() / '.steam/steam/steamapps/common/Factorio/bin/x64/factorio']
        path = next((p for p in candidates if p.is_file()), candidates[0])
    if not path.is_file():
        raise ValueError('Factorio not found. Set FACTORIO_EXE or use --factorio.')
    return path


def config(args):
    exe = executable(args)
    configured = args.data_dir or os.environ.get('FACTORIO_DATA_DIR')
    candidates = [Path(configured).expanduser().resolve()] if configured else [p / 'data' for p in list(exe.parents)[:3]]
    data = next((p for p in candidates if (p / 'base').is_dir()), None)
    if not data:
        raise ValueError('Game data not found. Set FACTORIO_DATA_DIR or use --data-dir.')
    WORK.mkdir(exist_ok=True)
    path = WORK / 'config.ini'
    path.write_text(f'[path]\nread-data={data.as_posix()}\nwrite-data={WORK.as_posix()}\n[general]\ncheck-updates=false\n', encoding='utf-8')
    return exe, path


def run(exe, cfg, mods, label, extra, marker=False, timeout=120):
    log = WORK / f'{label}.log'
    env = os.environ.copy()
    if 'steamapps' in str(exe).lower():
        env['SteamAppId'] = '427520'
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
    with log.open('w', encoding='utf-8') as output:
        result = subprocess.run([str(exe), '--config', str(cfg), '--mod-directory', str(mods), *extra],
                                stdout=output, stderr=subprocess.STDOUT, env=env, startupinfo=startup, timeout=timeout)
    text = log.read_text(encoding='utf-8', errors='replace')
    if result.returncode or re.search(r'Error:|non-recoverable error|Error while running', text) or (marker and 'CURSOR ALIGNMENT TESTS PASSED' not in text):
        raise ValueError(f'Factorio check failed. See {log}\n{text[-5000:]}')
    return text


def test(args, client=False):
    build()
    exe, cfg = config(args)
    folder = WORK / uuid.uuid4().hex
    folder.mkdir()
    for label in (('client',) if client else ('release-load', 'behavior')):
        mods = folder / label
        mods.mkdir()
        (mods / 'mod-list.json').write_text(json.dumps({'mods': [{'name': 'base', 'enabled': True}, {'name': INFO['name'], 'enabled': True}]}), encoding='utf-8')
        if label == 'release-load':
            shutil.copy2(PACKAGE, mods)
        else:
            with zipfile.ZipFile(PACKAGE) as archive:
                archive.extractall(mods)
            path = mods / NAME / 'control.lua'
            original = path.read_text(encoding='utf-8')
            prefix = '' if client else (ROOT / 'tests/prefix.lua').read_text(encoding='utf-8')
            suffix = (ROOT / ('tests/native.lua' if client else 'tests/smoke.lua')).read_text(encoding='utf-8')
            path.write_text(prefix + '\n' + original + '\n' + suffix, encoding='utf-8')
        save = WORK / f'{label}.zip'
        save.unlink(missing_ok=True)
        text = run(exe, cfg, mods, label, ['--create', str(save)], label == 'behavior')
        if not save.is_file() or not re.search(r'^Done\.', text, re.M):
            raise ValueError(f'Map creation did not finish: {label}')
        if client:
            run(exe, cfg, mods, 'client', ['--benchmark-graphics', str(save), '--benchmark-ticks', '360', '--disable-audio', '--window-size', '1280x960'], True)
        print(f'PASS: {label}')


def mod_directory(args):
    configured = args.mod_dir or os.environ.get('FACTORIO_MOD_DIR')
    if configured:
        return Path(configured).expanduser().resolve()
    if os.name == 'nt':
        return Path(os.environ['APPDATA']) / 'Factorio/mods'
    if sys.platform == 'darwin':
        return Path.home() / 'Library/Application Support/factorio/mods'
    return Path.home() / '.factorio/mods'


def install(args):
    test(args)
    folder = mod_directory(args)
    folder.mkdir(parents=True, exist_ok=True)
    destination, listing = folder / PACKAGE.name, folder / 'mod-list.json'
    settings = json.loads(listing.read_text(encoding='utf-8-sig')) if listing.exists() else {'mods': []}
    backup = ROOT / 'backups' / uuid.uuid4().hex
    backup.mkdir(parents=True)
    for path in (listing, destination):
        if path.exists():
            shutil.copy2(path, backup / path.name)
    entries = [entry for entry in settings['mods'] if entry['name'] == INFO['name']]
    if entries:
        for entry in entries:
            entry['enabled'] = True
    else:
        settings['mods'].append({'name': INFO['name'], 'enabled': True})
    shutil.copyfile(PACKAGE, destination)
    if destination.read_bytes() != PACKAGE.read_bytes():
        raise ValueError('Installed ZIP differs from package')
    # Stage the list in the target filesystem for an atomic replacement.
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=folder, delete=False) as output:
        json.dump(settings, output, indent=2)
        temporary = Path(output.name)
    os.replace(temporary, listing)
    print(f'Installed and enabled: {destination}\nBackup: {backup}\nRestart Factorio to load the mod.')


def clean():
    if WORK.is_symlink() or WORK.resolve().parent != ROOT.resolve():
        raise ValueError('Unsafe cleanup path')
    if WORK.exists():
        shutil.rmtree(WORK)
    for path in (PACKAGE, PACKAGE.with_suffix('.zip.sha256'), PACKAGE.with_suffix('.zip.tmp')):
        path.unlink(missing_ok=True)
    print('Generated work and current package removed; source, backups and installed mods preserved.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('task', nargs='?', default='help', choices=['help','check','build','compile','test','test-client','install','clean','rebuild','doctor'])
    parser.add_argument('--factorio')
    parser.add_argument('--data-dir')
    parser.add_argument('--mod-dir')
    args = parser.parse_args()
    if args.task == 'help': parser.print_help()
    elif args.task == 'check': check()
    elif args.task in ('build','compile'): build()
    elif args.task == 'test': test(args)
    elif args.task == 'test-client': test(args, True)
    elif args.task == 'install': install(args)
    elif args.task == 'clean': clean()
    elif args.task == 'rebuild': clean(); test(args)
    elif args.task == 'doctor':
        exe, cfg = config(args)
        print(f'Factorio: {exe}\nConfig: {cfg}\nMods: {mod_directory(args)}')
        subprocess.run([str(exe), '--version'], check=True)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        sys.exit(1)
