import UIKit

/// Public-API adapter for the unmodified upstream TheseusTabBar.
/// MarkFont supplies its four destinations and positions the original control.
@objc(FMTheseusTabBar)
final class FMTheseusTabBar: UIView {
    private let bar = TheseusTabBar()

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
        // Set MarkFont's initial destination before the original item views exist.
        bar.selectedIndex = 1
        bar.items = [
            TheseusTabBarItem(icon: UIImage(systemName: "link"), title: titles[0]),
            TheseusTabBarItem(icon: Self.aaGlyph(), title: titles[1]),
            TheseusTabBarItem(icon: UIImage(systemName: "books.vertical"), title: titles[2]),
            TheseusTabBarItem(icon: UIImage(systemName: "gearshape"), title: titles[3])
        ]
        bar.onItemSelected = { [weak self] index in
            self?.selectionHandler?(index)
        }
        addSubview(bar)
    }

    required init?(coder: NSCoder) { fatalError("Use init(titles:)") }

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

    override var intrinsicContentSize: CGSize { bar.intrinsicContentSize }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The parent uses the original control's intrinsic size. No changes
        // to barHeight, preferredItemWidth, lens size, material or clipping.
        bar.frame = bounds
    }

    @objc(setSelectedIndex:animated:)
    func setSelectedIndex(_ index: Int, animated: Bool) {
        guard bar.items.indices.contains(index), index != bar.selectedIndex else { return }
        // Keep the Objective-C routing selector; upstream owns the animation.
        bar.selectedIndex = index
    }
}
