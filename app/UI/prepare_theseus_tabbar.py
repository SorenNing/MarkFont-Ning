#!/usr/bin/env python3
"""Append MarkFont's minimal bridge extension; never mutate the pinned vendor source.
Usage: python3 prepare_theseus_tabbar.py INPUT/TheseusTabBar.swift OUTPUT.swift
Compile OUTPUT instead of INPUT, in the SAME module as the remaining Theseus files.
"""
import hashlib
import os
from pathlib import Path
import sys
import tempfile

source = Path(sys.argv[1]).read_bytes()
EXPECTED_SHA256 = "20e29ef46313b5a96daea9b1146ce7726a392a91795c1d574b998fe22509d921"
if hashlib.sha256(source).hexdigest() != EXPECTED_SHA256:
    raise SystemExit("TheseusTabBar.swift differs from pinned 71ca1c1; review adapter before updating")
extension = '''
// MarkFont bridge only; the complete pinned implementation above is unchanged.
extension TheseusTabBar {
    func markfontSelect(_ index: Int, animated: Bool) {
        guard items.indices.contains(index) else { return }
        isCommittingDrag = true
        selectedIndex = index
        isCommittingDrag = false
        updateSelection(animated: animated)
    }

    // Called only on host visibility transitions. The original lens keeps its
    // own source, capture chain, container, clipping and rendering lifecycle.
    func markfontSynchronize(host: UIView, active: Bool) {
        if !active {
            teardownTheseus()
            resetAdaptation()
            backgroundGlassView.pauseRendering()
            selectionView.pauseRendering()
            return
        }
        // Base surfaces must not recapture the application host or foreground
        // siblings. This does not alter the original moving lens's capture.
        var exclusions: [UIView] = [host]
        var child: UIView = host
        for _ in 0..<32 {
            guard let parent = child.superview else { break }
            if let index = parent.subviews.firstIndex(where: { $0 === child }) {
                exclusions.append(contentsOf: parent.subviews.dropFirst(index + 1))
            }
            child = parent
        }
        for glass in [backgroundGlassView, selectionView] {
            glass.sourceView = host.window
            glass.setCaptureExcludedViews(exclusions)
            glass.resumeRendering()
        }
    }
}
'''
output = Path(sys.argv[2])
output.parent.mkdir(parents=True, exist_ok=True)
generated = b"// Generated from pinned Theseus; see app/UI/prepare_theseus_tabbar.py.\n" + source + extension.encode("utf-8")
# Recursive make passes share this architecture-independent source. Avoid
# touching unchanged output, and never expose a partially written Swift file.
if not output.is_file() or output.read_bytes() != generated:
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=output.parent, prefix=output.name + ".", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(generated)
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
