#!/usr/bin/env python3
"""Generate MarkFont's layout adapter; never mutate the pinned vendor source.
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
text = source.decode()

def replace(old, new):
    global text
    if text.count(old) != 1:
        raise SystemExit("Expected exactly one adaptation anchor: " + old[:100])
    text = text.replace(old, new, 1)

replace("    private var itemViews: [TabItemView] = []", "    private var itemViews: [TabItemView] = []\n    private var markfontWasActive: Bool?")
replace("usesIOS26Look ? 0 : Self.bodyInset", "0 // MarkFont: exact outer capsule")
replace("usesIOS26Look ? 0 : Self.chromeSideInset", "0 // MarkFont: exact outer capsule")
replace("usesIOS26Look ? (Self.iOS26PlatterHeight - barHeight) / 2 : Self.chromeOutset", "0 // MarkFont: 72pt in either optical mode")
replace("usesIOS26Look ? 10.25 : 15", "0 // MarkFont: four equal-width slots")
replace("CGRect(x: barFrame.minX + CGFloat(index) * itemWidth, y: 0, width: itemWidth, height: itemHeight)", "CGRect(x: barFrame.minX + CGFloat(index) * itemWidth, y: 7, width: itemWidth, height: max(0, itemHeight - 14))")
replace("""        let size = pillSize
        return CGRect(x: itemFrame.midX - size.width / 2, y: itemFrame.midY - size.height / 2, width: size.width, height: size.height)""", """        // MarkFont: retain the original slot-relative selection footprint.
        return itemFrame.insetBy(dx: 4, dy: 4)""")
replace("""        if selectionView.shape.cornerRadius != frame.height / 2 {
            selectionView.shape.cornerRadius = frame.height / 2
        }""", """        if selectionView.shape.cornerRadius != 25 {
            selectionView.shape.cornerRadius = 25
        }""")
replace("""        backgroundView.clipsToBounds = false""", """        backgroundView.layer.cornerRadius = backgroundView.bounds.height / 2
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.clipsToBounds = true""")
replace("""        let glassView = TheseusView(configuration: config)
        glassView.sourceView = sourceView""", """        let glassView = FMTheseusLensView(configuration: config)
        glassView.backgroundColor = .clear
        glassView.isOpaque = false
        glassView.layer.cornerCurve = .continuous
        glassView.clipsToBounds = true
        glassView.sourceView = sourceView""")
replace("""        glassView.shape = shape
    }

    /// Negative is the shader's lens sentinel""", """        glassView.shape = shape
        glassView.layer.cornerRadius = glassFrame.height / 2
    }

    /// Negative is the shader's lens sentinel""")
# Explicit non-default unselectedTintColor already bypasses upstream vibration.
# Keep the selected label color unchanged at rest and under the real lens.
start = text.index("    private func vibrantTint(_ tint: UIColor,")
end = text.index("\n    private func updateItemColors()", start)
text = text[:start] + "    private func vibrantTint(_ tint: UIColor, over glass: UIColor, plus brightening: CGFloat = 0) -> UIColor { tint }\n\n" + text[end:]
replace("""        stackView.alignment = .center""", """        stackView.alignment = .fill""")
replace("""            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -0.67),""", """            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),""")
replace("iconBox.widthAnchor.constraint(equalToConstant: TabItemView.iconSize.width)", "iconBox.widthAnchor.constraint(greaterThanOrEqualToConstant: TabItemView.iconSize.width)")
replace("static let iconSize = CGSize(width: 38, height: 28)", "static let iconSize = CGSize(width: 26, height: 21)")
replace("static let titleNudge: CGFloat = 0.15", "static let titleNudge: CGFloat = 0")
replace("static let titleFont = UIFont.systemFont(ofSize: 10, weight: .medium)", "static let titleFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)")
replace("static let selectedTitleFont = UIFont.systemFont(ofSize: 10, weight: .semibold)", "static let selectedTitleFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)")
replace("UIImage.SymbolConfiguration(pointSize: 18, weight: .medium, scale: .large)", "UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)")
# Eliminate mode-dependent title shifts while retaining capture-twin machinery.
start = text.index("    private var titleOffset: CGPoint {")
end = text.index("\n    func configure(with item:", start)
text = text[:start] + "    private var titleOffset: CGPoint { .zero }\n" + text[end:]
# Full-width iconBox is a layout spacer, not the image's actual drawing width.
replace("""        guard let image = image, isSymbol(image) else { return box }""", """        guard let image = image, isSymbol(image) else {
            return CGRect(x: box.midX - 13, y: box.minY, width: 26, height: 21)
        }""")
text += '''
// MarkFont application adapter. Compiled alongside, never written over, vendor.
private final class FMTheseusLensView: TheseusView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Track animated bounds before display, independently of the host timer.
        // Leave the shader's negative lens-radius sentinel untouched.
        layer.cornerRadius = bounds.height / 2
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }
}
extension TheseusTabBar {
    func markfontSelect(_ index: Int, animated: Bool) {
        guard items.indices.contains(index) else { return }
        isCommittingDrag = true
        selectedIndex = index
        isCommittingDrag = false
        updateSelection(animated: animated && !UIAccessibility.isReduceMotionEnabled)
    }

    func markfontSynchronize(host: UIView, active: Bool) {
        // The base samples the real window, never its own chrome/labels or any
        // later foreground sibling. The moving lens retains the vendor's own
        // composite capture chain, including its deliberately drawn item twins.
        var exclusions: [UIView] = [host]
        var child: UIView = host
        for _ in 0..<32 {
            guard let parent = child.superview else { break }
            if let i = parent.subviews.firstIndex(where: { $0 === child }) {
                exclusions.append(contentsOf: parent.subviews.dropFirst(i + 1))
            }
            child = parent
        }
        for glass in [backgroundGlassView, selectionView] {
            if glass.sourceView !== host.window { glass.sourceView = host.window }
            glass.setCaptureExcludedViews(exclusions)
        }
        if let lens = theseusView {
            lens.setCaptureExcludedViews(exclusions.filter { $0 !== host && $0 !== lens })
        }
        if !active && markfontWasActive != false {
            // The lens lives beside the root view; removing just the host would
            // otherwise leave it visible/running while the page is hidden.
            teardownTheseus()
            resetAdaptation()
        }
        markfontWasActive = active
        for glass in [backgroundGlassView, selectionView, theseusView].compactMap({ $0 }) {
            glass.backgroundColor = .clear
            glass.isOpaque = false
            glass.layer.cornerRadius = min(abs(glass.shape.cornerRadius), glass.bounds.height / 2)
            glass.layer.cornerCurve = .continuous
            glass.clipsToBounds = true
            let visible = active && !glass.isHidden && glass.alpha > 0.001
            if visible { glass.resumeRendering() } else { glass.pauseRendering() }
        }
    }
}
'''
output = Path(sys.argv[2])
output.parent.mkdir(parents=True, exist_ok=True)
generated = ("// Generated from pinned Theseus; see app/UI/prepare_theseus_tabbar.py.\n" + text).encode("utf-8")
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
