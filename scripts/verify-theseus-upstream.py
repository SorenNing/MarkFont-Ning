#!/usr/bin/env python3
"""Verify the exact pinned upstream inputs; never generate or modify sources."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
PIN = '71ca1c127a4e7fe3387361f160c4890dbd427f66'
MANIFEST_HASH = 'd5c8cbf77e24e2b795dd4a56555ced230af019765fb84a78197d1880c5abf2f9'


def verify(root=ROOT):
    vendor = root / 'vendor/Theseus'
    manifest = json.loads((vendor / 'UPSTREAM.json').read_text())
    assert manifest['commit'] == PIN, 'Unexpected upstream revision'
    files = manifest['files']
    frozen = json.dumps(files, sort_keys=True, separators=(',', ':')).encode()
    assert hashlib.sha256(frozen).hexdigest() == MANIFEST_HASH, 'Pinned hashes changed'
    assert len(files) == 37
    for name, digest in files.items():
        path = vendor / name
        assert path.is_file() and not path.is_symlink(), name
        assert hashlib.sha256(path.read_bytes()).hexdigest() == digest, name
    swift = sorted(vendor.glob('Sources/Theseus/**/*.swift'))
    metal = sorted(vendor.glob('Sources/Theseus/**/*.metal'))
    assert len(swift) == 33 and len(metal) == 1
    assert {str(p.relative_to(vendor)) for p in swift + metal} == {
        n for n in files if n.endswith(('.swift', '.metal')) and n.startswith('Sources/')
    }, 'Unpinned compile inputs'
    return {'upstream_commit': PIN, 'verified_files': len(files),
            'direct_swift_inputs': len(swift), 'direct_metal_inputs': len(metal)}


if __name__ == '__main__':
    try:
        print(json.dumps(verify()))
    except (AssertionError, OSError, ValueError) as error:
        sys.exit('Theseus upstream verification failed: ' + str(error))
