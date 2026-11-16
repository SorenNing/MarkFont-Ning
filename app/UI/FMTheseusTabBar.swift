import UIKit
import QuartzCore

/// Compiled in the same module as Theseus and the generated tab-bar adapter.
/// MarkFont owns routing and geometry; Theseus owns the material and gestures.
@objc(FMTheseusTabBar)
final class FMTheseusTabBar: UIView {
    private let bar = TheseusTabBar()
    private var refreshLink: CADisplayLink?
    private var refreshTarget: FMTheseusRefreshTarget?
    private var lastRefresh: CFTimeInterval = 0
    private var lastVisibility: Bool?

    @objc var selectionHandler: ((Int) -> Void)?
    @objc var selectedIndex: Int { bar.selectedIndex }

    @objc(initWithTitles:)
    init(titles: [String]) {
        super.init(frame: .zero)
        precondition(titles.count == 4)
        backgroundColor = .clear
        isOpaque = false
        // Preserve the original optical outsets and press/lift excursion.
        clipsToBounds = false
        accessibilityIdentifier = "markfont.theseus.tabbar"
        bar.barHeight = 72
        bar.items = [
            TheseusTabBarItem(icon: UIImage(systemName: "link"), title: titles[0]),
            TheseusTabBarItem(icon: Self.aaGlyph(), title: titles[1]),
            TheseusTabBarItem(icon: UIImage(systemName: "books.vertical"), title: titles[2]),
            TheseusTabBarItem(icon: UIImage(systemName: "gearshape"), title: titles[3])
        ]
        bar.markfontSelect(1, animated: false)
        bar.onItemSelected = { [weak self] index in
            self?.selectionHandler?(index)
        }
        addSubview(bar)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationVisibilityChanged),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationVisibilityChanged),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(titles:)") }

    deinit {
        refreshLink?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private static func aaGlyph() -> UIImage {
        // The existing tab used a 17pt heavy UILabel reading Aa. Rasterize only
        // that glyph into a transparent template; the bar/lens are real Theseus.
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: 26, height: 21), format: format).image { _ in
            let text = "Aa" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: (26 - size.width) / 2, y: (21 - size.height) / 2),
                      withAttributes: attributes)
        }.withRenderingMode(.alwaysTemplate)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // preferredItemWidth only limits the width. A deliberately generous
        // public value fills the exact width regardless of optical mode scale.
        let preferredWidth = max(bounds.width, 1)
        if bar.preferredItemWidth != preferredWidth { bar.preferredItemWidth = preferredWidth }
        bar.frame = bounds
        bar.layoutIfNeeded()
        synchronizeVisibility()
        bar.invalidateBackground()
    }

    @objc(setSelectedIndex:animated:)
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard bar.items.indices.contains(index), index != bar.selectedIndex else { return }
        bar.markfontSelect(index, animated: animated)
        bar.invalidateBackground()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        lastVisibility = nil
        refreshLink?.invalidate()
        refreshLink = nil
        refreshTarget = nil
        if window != nil {
            let target = FMTheseusRefreshTarget()
            target.owner = self
            refreshTarget = target
            let link = CADisplayLink(target: target, selector: #selector(FMTheseusRefreshTarget.tick(_:)))
            link.preferredFramesPerSecond = 30
            link.add(to: .main, forMode: .common)
            refreshLink = link
        }
        synchronizeVisibility()
    }

    private var isActuallyVisible: Bool {
        guard let window, UIApplication.shared.applicationState == .active,
              convert(bounds, to: window).intersects(window.bounds) else { return false }
        var current: UIView? = self
        // Only public ancestry; no inspection or mutation of vendor internals.
        for _ in 0..<32 {
            guard let view = current else { return true }
            if view.isHidden || view.alpha <= 0.001 { return false }
            if view === window { return true }
            current = view.superview
        }
        // Deep attached hierarchies are still visible. Returning false here
        // incorrectly paused the whole bar during ordinary layout callbacks.
        return current != nil
    }

    private func synchronizeVisibility() {
        let active = isActuallyVisible
        if lastVisibility != active {
            lastVisibility = active
            bar.markfontSynchronize(host: self, active: active)
            if active { bar.invalidateBackground() }
        }
    }

    @objc private func applicationVisibilityChanged() {
        refreshLink?.isPaused = UIApplication.shared.applicationState != .active
        synchronizeVisibility()
    }

    fileprivate func refresh(at time: CFTimeInterval) {
        synchronizeVisibility()
        guard lastVisibility == true, time - lastRefresh >= 1.0 / 30.0 else { return }
        lastRefresh = time
        // Common-mode refresh follows page scrolling. The upstream bar also
        // drives its native moving lens independently at its intended cadence.
        bar.invalidateBackground()
    }
}

private final class FMTheseusRefreshTarget: NSObject {
    weak var owner: FMTheseusTabBar?
    @objc func tick(_ link: CADisplayLink) { owner?.refresh(at: link.timestamp) }
}
