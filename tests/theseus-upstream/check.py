#!/usr/bin/env python3
"""Source and Makefile wiring checks only; no compilation or CI dispatch."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('upstream', root / 'scripts/verify-theseus-upstream.py')
upstream = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upstream)
report = upstream.verify(root)
legacy = ['app/UI/prepare_theseus_tabbar.py', 'app/UI/theseus_geometry.py',
          'tests/theseus-geometry/check.py']
assert all(not (root / name).exists() for name in legacy)
wrapper = (root / 'app/UI/FMTheseusTabBar.swift').read_text()
# The wrapper may supply items, selection and frame, but never take over
# engine state, dimensions, styles, capture, shaders or animation cadence.
allowed = {'selectedIndex', 'items', 'onItemSelected', 'intrinsicContentSize', 'frame'}
import re
assert set(re.findall(r'\bbar\.(\w+)', wrapper)) <= allowed
for forbidden in ['CADisplayLink', 'markfontSelect', 'markfontSynchronize',
                  'CAShapeLayer', 'NotificationCenter', 'pauseRendering',
                  'resumeRendering', 'layer.mask', 'extension Theseus',
                  'TheseusSettings', 'setCaptureExcludedViews']:
    assert forbidden not in wrapper, forbidden
assert wrapper.count('TheseusTabBarItem(') == 4
assert 'bar.selectedIndex = 1' in wrapper
assert 'override var intrinsicContentSize: CGSize { bar.intrinsicContentSize }' in wrapper
controller = (root / 'app/UI/FMTabBarController.m').read_text()
block = controller.split('    [self.view addSubview:self.tabBar];', 1)[1].split('    [self installSwipeGestures];', 1)[0]
assert 'centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor' in block
assert 'heightAnchor' not in block and 'widthAnchor' not in block
assert 'constant:-14' in block

with tempfile.TemporaryDirectory() as directory:
    temp = Path(directory)
    # Parse the real Makefile with lightweight include stubs. It still executes
    # the real pinned verifier and Bundle.module shim step, never a compiler.
    theos = temp / 'theos'
    mk = theos / 'makefiles'; mk.mkdir(parents=True)
    (mk / 'common.mk').write_text('THEOS_MAKE_PATH := ' + str(mk) + '\nTHEOS_PLATFORM_NAME := iphone\n')
    (mk / 'application.mk').write_text(
        '$(file >$(AUDIT_OUTPUT),$(FontManager_FILES))\n.PHONY: audit\naudit:\n\t@true\n')
    expected = sorted((root / 'vendor/Theseus/Sources/Theseus').rglob('*.swift'))
    for scheme in ['rootless', 'roothide']:
        manifest = temp / (scheme + '.inputs')
        generated = temp / scheme
        command = ['make', '-s', '-f', 'Makefile', 'audit', 'THEOS=' + str(theos),
                   'THEOS_PACKAGE_SCHEME=' + scheme, 'AUDIT_OUTPUT=' + str(manifest),
                   'MARKFONT_THESEUS_GENERATED=' + str(generated)]
        result = subprocess.run(command, cwd=root / 'app', capture_output=True, text=True)
        assert result.returncode == 0, result.stdout + result.stderr
        inputs = [(root / 'app' / name).resolve() for name in manifest.read_text().split()]
        swift = [p for p in inputs if p.suffix == '.swift']
        assert len(swift) == len(set(swift)) == 35
        assert set(expected) < set(swift)
        assert set(swift) - set(expected) == {root / 'app/UI/FMTheseusTabBar.swift', generated / 'TheseusBundle.swift'}
        assert sorted(p.name for p in generated.iterdir()) == ['TheseusBundle.swift']
        # A stray derivative from an old build can never re-enter the inputs.
        for name in ['TheseusTabBar.swift', 'TheseusView.swift', 'TheseusRenderer.swift', 'CaptureCompensation.swift']:
            (generated / name).write_text('THIS MUST NEVER BE COMPILED\n')
        again = subprocess.run(command, cwd=root / 'app', capture_output=True, text=True)
        assert again.returncode == 0
        assert inputs == [(root / 'app' / name).resolve() for name in manifest.read_text().split()]
    # The production verifier must reject both modified inputs and a modified
    # manifest; do this in a temporary copy without touching vendor originals.
    probe = temp / 'probe'
    shutil.copytree(root / 'vendor/Theseus', probe / 'vendor/Theseus')
    target = probe / 'vendor/Theseus/Sources/Theseus/Components/TheseusTabBar.swift'
    target.write_bytes(target.read_bytes() + b'\n')
    try:
        upstream.verify(probe)
    except AssertionError:
        pass
    else:
        raise AssertionError('Altered upstream source was accepted')
    m = probe / 'vendor/Theseus/UPSTREAM.json'
    data = json.loads(m.read_text())
    data['files']['Sources/Theseus/Components/TheseusTabBar.swift'] = hashlib.sha256(target.read_bytes()).hexdigest()
    m.write_text(json.dumps(data))
    try:
        upstream.verify(probe)
    except AssertionError:
        pass
    else:
        raise AssertionError('Altered pinned manifest was accepted')
report.update({'schemes_verified': ['rootless', 'roothide'], 'compiled_swift_inputs': 35,
               'generated_control_sources': 0, 'generated_resource_shims': 1,
               'legacy_sources_unreachable': True, 'tamper_rejected': True,
               'native_swift_checked': False, 'device_visual_checked': False})
print(json.dumps(report))
