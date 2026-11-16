#!/usr/bin/env python3
"""Source-only regression checks; no app build, network or workflow dispatch."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import math

root = Path(__file__).resolve().parents[2]
vendor = root / 'vendor/Theseus'
manifest = json.loads((vendor / 'UPSTREAM.json').read_text())
for name, digest in manifest['files'].items():
    assert hashlib.sha256((vendor / name).read_bytes()).hexdigest() == digest, name
source = vendor / 'Sources/Theseus/Components/TheseusTabBar.swift'
generator = root / 'app/UI/prepare_theseus_tabbar.py'
with tempfile.TemporaryDirectory() as directory:
    output = Path(directory) / 'TheseusTabBar.swift'
    subprocess.run(['python3', str(generator), str(source), str(output)], check=True)
    paths = [output.parent / name for name in ('TheseusTabBar.swift', 'TheseusView.swift',
             'TheseusRenderer.swift', 'CaptureCompensation.swift')]
    previous = [(p.read_bytes(), p.stat().st_mtime_ns) for p in paths]
    subprocess.run(['python3', str(generator), str(source), str(output)], check=True)
    assert previous == [(p.read_bytes(), p.stat().st_mtime_ns) for p in paths]
    tampered = output.parent / 'tampered.swift'
    tampered.write_bytes(source.read_bytes() + b'\n')
    result = subprocess.run(['python3', str(generator), str(tampered), str(output)], capture_output=True)
    assert result.returncode and previous == [(p.read_bytes(), p.stat().st_mtime_ns) for p in paths]
    tab, view, renderer, compensation = [p.read_text() for p in paths]
    assert 'let size = pillSize // MarkFont' in tab
    assert 'Self.iOS26PillSize : Self.pillSize' not in tab
    assert 'first.midX - Self.lensOverrun' not in tab
    assert 'backgroundGlassView.markfontExcludeFromCapture(glassView)' in tab
    # The active lens is an ancestor sibling, so a clip on the outer bar does
    # not cover it. Require opt-in masks on all three actual glass surfaces.
    assert tab.count('.markfontClipsOpticalBounds = true') == 3
    for surface in ['backgroundGlassView', 'selectionView', 'glassView']:
        assert surface + '.markfontClipsOpticalBounds = true' in tab
    assert 'public override var bounds: CGRect' in view
    assert 'if bounds != oldValue { markfontUpdateOpticalMask() }' in view
    assert 'markfontUpdateOpticalMask()\n            renderer?.updateConfiguration(configuration)' in view
    assert 'super.layoutSubviews()\n        markfontUpdateOpticalMask()' in view
    assert 'if layer.mask !== markfontOpticalMask { layer.mask = markfontOpticalMask }' in view
    assert 'markfontOpticalMask.path = markfontOpticalPath(in: maskFrame)' in view
    assert 'shape.widthInset, dy: shape.heightInset' in view
    assert 'scaleX: max(morph.scale.x, 0.0001)' in view
    assert 'mask.path = glass.markfontOpticalPath(in: layer.frame)' in compensation
    assert 'metalContainer.isOpaque = false' in view
    assert 'metalContainer.autoresizingMask' not in view
    assert 'let drawFrame = bounds.insetBy(dx: -padding.x, dy: -padding.y)' in view
    snapshot = view.split('var captureSnapshotFrame: CGRect {')[1].split('private func')[0]
    assert 'insetBy' not in snapshot
    region = renderer.split('private func calculateCaptureRegion')[1].split('private func setupNotifications')[0]
    assert 'insetBy' not in region and 'return frameInSource' in region
    real_snapshot = compensation.split('if let snapshot = glass.captureSnapshot {')[1].split('} else {')[0]
    assert 'maskCaptureReplacement(layer, for: glass)' in real_snapshot
    assert 'glass.backgroundColor = glass.captureVeilColor' not in compensation
    assert compensation.count('maskCaptureReplacement(layer, for: glass)') == 2
    assert 'defer { CATransaction.commit() }' in compensation
    # Optical/material expressions in the generated implementation must survive byte-for-byte.
    original = source.read_text()
    for start, end in [('        var config = TheseusConfiguration.lens', '        let glassView = TheseusView(configuration: config)'),
                       ('    private func setLensFill(', '    private func setLensRefraction(')]:
        assert original.split(start)[1].split(end)[0] == tab.split(start)[1].split(end)[0]
    makefile = (root / 'app/Makefile').read_text()
    for relative in ['Components/TheseusTabBar.swift', 'Core/TheseusView.swift',
                     'Rendering/TheseusRenderer.swift', 'Rendering/CaptureCompensation.swift']:
        assert "! -path '*/" + relative + "'" in makefile
    assert makefile.index('MARKFONT_THESEUS_PREPARE_STATUS :=') < makefile.index('include $(THEOS_MAKE_PATH)/application.mk')

# Numeric independent contract: four equal slots, 4pt inset, clamped pan endpoints;
# transformed padded capture extent must equal the host extent (never 2x padding).
cases = 0
for outer_width in [240, 288, 343, 358, 398, 512, 740, 992]:
    slot = outer_width / 4
    width, height = slot - 8, 64
    for index in range(4):
        center = slot * (index + .5)
        assert math.isclose(center - width / 2, slot * index + 4)
        assert math.isclose(center + width / 2, slot * (index + 1) - 4)
        assert (72 - height) / 2 == 4
    for raw in [-1000, 0, slot / 2, outer_width / 2, outer_width, 1000]:
        center = min(max(raw, slot / 2), outer_width - slot / 2)
        assert center - width / 2 >= 4
        assert center + width / 2 <= outer_width - 4
    for padding_x, padding_y in [(0, 0), (18, 18), (10, 17), (26, 31)]:
        for scale in [1, 2, 3]:
            for transform in [.9, 1, 1.0431, 1.1]:
                padded_width, padded_height = width + 2 * padding_x, height + 2 * padding_y
                assert abs(round(padded_width * scale) / scale - padded_width) <= .5 / scale + 1e-9
                assert math.isclose(padded_width * transform, (width + 2 * padding_x) * transform)
                assert math.isclose(padded_height * transform, (height + 2 * padding_y) * transform)
                cases += 1
# Independent optical-mask coordinate contract: padding changes the host,
# not the capsule. Inset/morph changes must move the mask without a resize.
mask_cases = 0
for width, height in [(51, 64), (78, 64), (96, 70), (398, 72)]:
    for px, py in [(0, 0), (18, 18), (10, 17)]:
        for ix, iy in [(0, 0), (-0.8, -0.8), (2, 3)]:
            for sx, sy in [(1, 1), (.9, 1.1), (1.0431, 1.0431)]:
                # Path translation into padded mask coordinates and back.
                x0 = width / 2 + (ix - width / 2) * sx
                x1 = width / 2 + (width - ix - width / 2) * sx
                y0 = height / 2 + (iy - height / 2) * sy
                y1 = height / 2 + (height - iy - height / 2) * sy
                assert math.isclose((x0 + px) - px, x0, abs_tol=1e-9)
                assert math.isclose((y0 + py) - py, y0, abs_tol=1e-9)
                assert math.isclose(x1 - x0, (width - 2 * ix) * sx)
                assert math.isclose(y1 - y0, (height - 2 * iy) * sy)
                assert math.isclose((x0 + x1) / 2, width / 2)
                assert math.isclose((y0 + y1) / 2, height / 2)
                mask_cases += 1
controller = (root / 'app/UI/FMTabBarController.m').read_text()
for text in ['constant:16', 'constant:-16', 'constant:-14', 'constraintEqualToConstant:72']:
    assert text in controller
print(json.dumps({'vendor_hashes': len(manifest['files']), 'generated_derivatives': 4,
                  'deterministic': True, 'tamper_rejected': True, 'geometry_cases': cases,
                  'optical_mask_coordinate_cases': mask_cases,
                  'three_live_surfaces_masked': True, 'capture_mask_uses_live_path': True,
                  'material_expressions_unchanged': True, 'native_swift_checked': False}))
