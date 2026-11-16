"""Reviewed geometry/capture-only changes; vendor and material/shader bytes stay pristine."""
from pathlib import Path
import hashlib
import json
import os
import tempfile

DERIVED = ('Core/TheseusView.swift', 'Rendering/TheseusRenderer.swift',
           'Rendering/CaptureCompensation.swift')


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError('Pinned source anchor changed: ' + old[:100])
    return text.replace(old, new, 1)


def publish(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_file() and path.read_bytes() == data:
        return
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name + '.', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def adapt_tabbar(text):
    # The moving lens is an ancestor-owned sibling, NOT a child of the bar.
    # Mask each actual glass surface; clipping only backgroundView misses it.
    text = replace_once(text,
        '        backgroundGlassView.providesCaptureSnapshot = true',
        '''        backgroundGlassView.markfontClipsOpticalBounds = true
        selectionView.markfontClipsOpticalBounds = true
        backgroundGlassView.providesCaptureSnapshot = true''')
    text = replace_once(text,
        '        let glassView = TheseusView(configuration: config)',
        '''        let glassView = TheseusView(configuration: config)
        glassView.markfontClipsOpticalBounds = true''')
    text = replace_once(text, 'usesIOS26Look ? 10.25 : 15', '0 // MarkFont: four equal slots across the full outer bar')
    text = replace_once(text, 'usesIOS26Look ? Self.iOS26PillSize : Self.pillSize',
                        'CGSize(width: max(contentBarFrame.width / CGFloat(max(items.count, 1)) - 8, 1), height: max(barHeight - 8, 1))')
    text = replace_once(text, 'let size = usesIOS26Look ? Self.iOS26LensSize : Self.lensSize', 'let size = pillSize // MarkFont: same 4pt inset at rest and while moving')
    # Optical-mode chrome is geometry too: retain material values while making
    # the visible body use the application's actual 72pt container in both modes.
    text = replace_once(text, 'usesIOS26Look ? (Self.iOS26PlatterHeight - barHeight) / 2 : Self.chromeOutset',
                        'bodyInset // MarkFont: visible glass remains inside the 72pt outer bounds')
    text = replace_once(text, 'usesIOS26Look ? 0 : Self.chromeSideInset',
                        '-bodyInset // MarkFont: visible body fills the outer width')
    text = replace_once(text, 'usesIOS26Look ? 0 : Self.iOS27LensOutset',
                        '0 // MarkFont: requested lens geometry already includes its 4pt inset')
    text = replace_once(text, '        theseusView = glassView\n        applyAdaptiveOverride()',
                        '        theseusView = glassView\n        backgroundGlassView.markfontExcludeFromCapture(glassView)\n        selectionView.markfontExcludeFromCapture(glassView)\n        applyAdaptiveOverride()')
    # Keep the original pan/follow springs but constrain their requested frame.
    text = replace_once(text, 'let centerX = min(max(point.x, first.midX - Self.lensOverrun), last.midX + Self.lensOverrun)',
                        'let centerX = min(max(point.x, first.midX), last.midX)')
    # The prewarm callback runs after the first visible layout. Pausing the
    # ancestor-owned lens there hides the selected pill until the next drag.
    text = replace_once(text, '                self.theseusView?.pauseRendering()',
                        '                self.theseusView?.resumeRendering()')
    # Do not remove the Metal view while UINavigationController is running a
    # pop transition. Removing it from didMoveToWindow can recursively tear
    # down the renderer while a frame callback is still in flight.
    text = replace_once(text,
        '''        theseusView?.pauseRendering()
        theseusView?.removeFromSuperview()
        theseusView = nil''',
        '''        if let glassView = theseusView {
            glassView.layer.removeAllAnimations()
            glassView.isHidden = true
            glassView.alpha = 0
            glassView.continuousUpdate = false
            glassView.pauseRendering()
        }''')
    return text


def adapt_view(text):
    text = replace_once(text, 'public class TheseusView: UIView {',
        '''public class TheseusView: UIView {

    // Opt-in for MarkFont's three tab-bar surfaces, including the lens that
    // lives outside the bar subtree. Not an outer rectangular bounds clip.
    var markfontClipsOpticalBounds = false {
        didSet { markfontUpdateOpticalMask() }
    }
    private let markfontOpticalMask = CAShapeLayer()

    public override var bounds: CGRect {
        didSet {
            if bounds != oldValue { markfontUpdateOpticalMask() }
        }
    }

    // Shared by the live surface and its capture twin. Shape insets can change
    // without changing drawableSize during drag/morph, so use configuration,
    // not a cached frame or the 30Hz host refresh.
    func markfontOpticalPath(in referenceFrame: CGRect) -> CGPath {
        let body = bounds.insetBy(dx: shape.widthInset, dy: shape.heightInset)
        guard body.width.isFinite, body.height.isFinite,
              body.width > 0, body.height > 0,
              morph.scale.x.isFinite, morph.scale.y.isFinite else {
            return UIBezierPath().cgPath
        }
        let limit = min(body.width, body.height) / 2
        let radius = shape.cornerRadius < 0 ? limit : min(max(shape.cornerRadius, 0), limit)
        let path = UIBezierPath(roundedRect: body, cornerRadius: radius)
        path.apply(CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY))
        path.apply(CGAffineTransform(scaleX: max(morph.scale.x, 0.0001),
                                     y: max(morph.scale.y, 0.0001)))
        path.apply(CGAffineTransform(translationX: bounds.midX - referenceFrame.minX,
                                     y: bounds.midY - referenceFrame.minY))
        return path.cgPath
    }

    private func markfontUpdateOpticalMask() {
        guard markfontClipsOpticalBounds else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let padding = configuration.drawPadding(for: bounds.size)
        let maskFrame = bounds.insetBy(dx: -padding.x, dy: -padding.y)
        markfontOpticalMask.frame = maskFrame
        markfontOpticalMask.contentsScale = metalLayer?.contentsScale ?? UIScreen.main.scale
        markfontOpticalMask.fillColor = UIColor.black.cgColor
        markfontOpticalMask.path = markfontOpticalPath(in: maskFrame)
        if layer.mask !== markfontOpticalMask { layer.mask = markfontOpticalMask }
        CATransaction.commit()
    }''')
    text = replace_once(text,
        '            renderer?.updateConfiguration(configuration)',
        '''            markfontUpdateOpticalMask()
            renderer?.updateConfiguration(configuration)''')
    text = replace_once(text,
        '''    public override func layoutSubviews() {
        super.layoutSubviews()''',
        '''    public override func layoutSubviews() {
        super.layoutSubviews()
        markfontUpdateOpticalMask()''')
    text = replace_once(text, '            self?.captureSnapshot = image\n            self?.snapshotDidUpdate?()',
        '''            guard let self = self, let size = self.metalLayer?.drawableSize,
                  image.width == Int(size.width), image.height == Int(size.height) else { return }
            self.captureSnapshot = image
            self.snapshotDidUpdate?()''')
    text = replace_once(text, '        if metalLayer.drawableSize != drawableSize {\n            metalLayer.drawableSize = drawableSize',
        '        if metalLayer.drawableSize != drawableSize {\n            captureSnapshot = nil\n            captureSnapshotOverride = nil\n            metalLayer.drawableSize = drawableSize')
    text = replace_once(text,
        'if oldValue.shape.padding != configuration.shape.padding || oldValue.glassRim != configuration.glassRim {',
        'if oldValue.drawPadding(for: bounds.size) != configuration.drawPadding(for: bounds.size) {')
    text = replace_once(text, '    private let captureExclusions = NSHashTable<UIView>.weakObjects()',
        '''    // Keep the ancestor-owned moving lens out of the base captures too.
    // Excluding only the bar subtree cannot hide this sibling of the root view.
    func markfontExcludeFromCapture(_ view: UIView) {
        captureExclusions.add(view)
        syncCaptureExclusions()
    }

    private let captureExclusions = NSHashTable<UIView>.weakObjects()''')
    text = replace_once(text,
        '        let padding = configuration.drawPadding(for: bounds.size)\n        return (metalLayerView?.frame ?? bounds).insetBy(dx: -padding.x, dy: -padding.y)',
        '        // The host already includes drawPadding; never expand it twice.\n        return metalLayerView?.frame ?? bounds')
    text = replace_once(text,
        '        metalContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]',
        '        // Only explicit layout owns the padded frame. UIView defaults opaque.\n        metalContainer.isOpaque = false\n        metalContainer.backgroundColor = .clear')
    text = replace_once(text,
        '        let paddingX = padding.x * scale\n        let paddingY = padding.y * scale\n        let drawableSize = CGSize(\n            width: (bounds.width * scale + paddingX * 2).rounded(),\n            height: (bounds.height * scale + paddingY * 2).rounded()\n        )',
        '''        // One extent for on-screen contents, readback and backdrop capture.
        let drawFrame = bounds.insetBy(dx: -padding.x, dy: -padding.y)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        metalLayerView?.frame = drawFrame
        let drawableSize = CGSize(
            width: max((drawFrame.width * scale).rounded(), 1),
            height: max((drawFrame.height * scale).rounded(), 1)
        )
        defer { CATransaction.commit() }''')
    return text


def adapt_renderer(text):
    text = replace_once(text,
        '        let excludedViews = ([hostView] + extraExcludedViews.allObjects).compactMap { $0 }\n        willCapture?()\n        defer { didCapture?() }',
        '''        let excludedViews = ([hostView] + extraExcludedViews.allObjects).compactMap { $0 }
        // Twin visibility and compensation swaps are capture-only, with no implicit animation.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        willCapture?()
        defer {
            didCapture?()
            CATransaction.commit()
        }''')
    text = replace_once(text,
        '        let padding = drawPadding\n        guard let metalLayer = metalLayer,\n              let superlayer = metalLayer.superlayer else {\n            return viewFrame.insetBy(dx: -padding.x, dy: -padding.y)\n        }',
        '        // metalLayer.frame is already the padded host extent.\n        guard let metalLayer = metalLayer,\n              let superlayer = metalLayer.superlayer else {\n            return viewFrame\n        }')
    text = replace_once(text,
        '''        // The drawable's padding scales with any transform on the glass view, so
        // the captured margin scales with it too.
        let scaleX = viewFrame.width > 0 ? frameInSource.width / viewFrame.width : 1
        let scaleY = viewFrame.height > 0 ? frameInSource.height / viewFrame.height : 1
        return frameInSource.insetBy(dx: -padding.x * scaleX, dy: -padding.y * scaleY)''',
        '''        // Conversion already carries the padding through the glass transform.
        return frameInSource''')
    return text


def adapt_compensation(text):
    text = replace_once(text, '        var entries: [Entry] = []',
                        '        CATransaction.begin()\n        CATransaction.setDisableActions(true)\n        var entries: [Entry] = []')
    text = replace_once(text, '    static func end(_ entries: [Entry]) {',
                        '    static func end(_ entries: [Entry]) {\n        defer { CATransaction.commit() }')
    text = replace_once(text, '''            host.isHidden = true
            if let snapshot = glass.captureSnapshot, !entry.metalHostWasHidden {''',
        '''            // A hidden Metal host denotes fallback/offscreen glass. Do not
            // invent a visible veil for it or capture a stale previous frame.
            guard !entry.metalHostWasHidden else {
                for subview in view.subviews { apply(to: subview, entries: &entries) }
                return
            }
            host.isHidden = true
            if let snapshot = glass.captureSnapshot {''')
    text = replace_once(text, '''                glass.layer.addSublayer(layer)
                entry.snapshotLayer = layer
            } else {
                glass.backgroundColor = glass.captureVeilColor
            }''',
        '''                // The temporary capture twin may contain an opaque rectangular
                // readback around the shader's shape. Bound only this copy,
                // retaining the original optical shadow and rim allowance.
                maskCaptureReplacement(layer, for: glass)
                glass.layer.addSublayer(layer)
                entry.snapshotLayer = layer
            } else {
                // Capture-only stand-in: preserve the original material colour,
                // but never paint the entire rectangular UIView background.
                let layer = CALayer()
                layer.frame = glass.bounds
                layer.backgroundColor = glass.captureVeilColor.cgColor
                maskCaptureReplacement(layer, for: glass)
                glass.layer.addSublayer(layer)
                entry.snapshotLayer = layer
            }''')
    text = replace_once(text, '    private static func apply(to view: UIView, entries: inout [Entry]) {',
        '''    // Opted-in tab-bar surfaces use exactly the same mask for live output
    // and capture replacements, including insets and morph-scale changes.
    private static func maskCaptureReplacement(_ layer: CALayer, for glass: TheseusView) {
        if glass.markfontClipsOpticalBounds {
            let mask = CAShapeLayer()
            mask.frame = layer.bounds
            mask.path = glass.markfontOpticalPath(in: layer.frame)
            mask.fillColor = UIColor.black.cgColor
            layer.mask = mask
            return
        }
        let shape = glass.shape
        let body = glass.bounds.insetBy(dx: shape.widthInset, dy: shape.heightInset)
            .offsetBy(dx: -layer.frame.minX, dy: -layer.frame.minY)
        let clipped = body.intersection(layer.bounds)
        let radius = shape.cornerRadius < 0 ? min(body.width, body.height) / 2
            : min(shape.cornerRadius, min(body.width, body.height) / 2)
        let mask = CAShapeLayer()
        mask.frame = layer.bounds
        mask.path = UIBezierPath(roundedRect: clipped, cornerRadius: max(min(radius, min(clipped.width, clipped.height) / 2), 0)).cgPath
        mask.fillColor = UIColor.black.cgColor
        layer.mask = mask
    }

    private static func apply(to view: UIView, entries: inout [Entry]) {''')
    return text


def prepare_support(vendor, output):
    vendor = Path(vendor)
    manifest = json.loads((vendor / 'UPSTREAM.json').read_text())
    for name in DERIVED:
        relative = 'Sources/Theseus/' + name
        source = (vendor / relative).read_bytes()
        if hashlib.sha256(source).hexdigest() != manifest['files'][relative]:
            raise ValueError('Vendor hash mismatch: ' + relative)
        adapter = {'Core/TheseusView.swift': adapt_view,
                   'Rendering/TheseusRenderer.swift': adapt_renderer,
                   'Rendering/CaptureCompensation.swift': adapt_compensation}[name]
        result = '// Generated geometry/capture derivative of pinned Theseus 71ca1c1.\n' + adapter(source.decode())
        publish(Path(output) / Path(name).name, result.encode())


if __name__ == '__main__':
    import sys
    prepare_support(sys.argv[1], sys.argv[2])
