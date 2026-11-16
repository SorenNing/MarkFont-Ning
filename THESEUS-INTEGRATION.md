# MarkFont Theseus bottom bar

The entire old `FMLiquidTabBarView` (blur, solid pill, border and item drawing)
is replaced by the real upstream `TheseusTabBar` through
`app/UI/FMTheseusTabBar.swift`. This includes the original glass body,
selection material, sibling-hosted refractive lens, capture twins, press lift,
finger-follow, spring and gesture implementations. There is no application
blur-only replacement or filled button background.

## Pinned upstream

- Repository: https://github.com/valzevul/Theseus
- Revision: `71ca1c127a4e7fe3387361f160c4890dbd427f66`
- Location: `vendor/Theseus`
- 37 pristine upstream files: 33 Swift implementation files, 1 Metal shader,
  `Package.swift`, `LICENSE`, `NOTICE`.
- `UPSTREAM.json` is MarkFont metadata with per-file SHA-256s.
- Original tab-bar SHA-256:
  `20e29ef46313b5a96daea9b1146ce7726a392a91795c1d574b998fe22509d921`.

## Exact retained geometry and behavior

`FMTabBarController.m` retains its four outer constraints verbatim: leading
16pt, trailing -16pt, safe-area bottom -14pt and height 72pt. The glass body is
a full-width 72pt capsule with radius 36pt, with no native 63pt/content-hugging
sizing. Four item slots divide the available width equally. Each slot starts
at y=7 and has height 58. Selection is its slot inset 4pt on each side: y=11,
height 50, width `(bar width / 4) - 8`, radius 25. Labels retain 9.5pt semibold,
2pt horizontal padding, icon top 9pt, icon box 26x21pt and spacing 1pt.

The four localized labels remain 挂载 / 字体 / 字体库 / 设置; link, Aa,
books.vertical and gearshape remain their glyphs. Aa uses the previous
17pt heavy type rendered into a transparent template, not a solid tile.
Selected/unselected glyph and label colors remain UIKit label/secondaryLabel.
Initial index remains 1. The controller still routes selections to its same
four existing navigation controllers, applies library selections to index 1,
reserves its original 100pt bottom safe-area inset, and retains page swipes
and pushed-page back behavior. Page swipe recognizers reject touches begun
in the bar so the original Theseus gestures own those touches. VoiceOver uses
the real upstream accessible item views, selected traits and activation.

## Why a generated adaptation is necessary

Upstream exposes `barHeight` and `preferredItemWidth`, but the original 15pt
horizontal item inset, fixed 80x53.5 selection, optical-mode-specific chrome
outsets and native text metrics are private. Public properties alone cannot
preserve the screenshot's geometry. The application owns
`app/UI/prepare_theseus_tabbar.py`; it verifies the entire pinned source SHA
and checks replacement anchors before producing a build-only derived source.
An upstream update fails closed and requires reviewing the adapter.

The generated source changes only the application geometry/typography/colors,
clipping and bridge control methods. It retains the original bar, shader,
lens material, lens motion, capture-twin, spring and gesture code. The moving
lens retains its native 96x70pt optical size (90x70pt in iOS26 optical mode)
and lift excursion while interacting; the resting footprint stays exact.
Vendor files are not edited. The derived Swift is visibly marked generated;
third-party attribution discloses these adaptations.

## Build contract

Run from `app`:

```sh
python3 UI/prepare_theseus_tabbar.py \
  ../vendor/Theseus/Sources/Theseus/Components/TheseusTabBar.swift \
  /path/to/build-output/TheseusTabBar.swift
```

Compile that generated file INSTEAD OF the original vendor tab-bar file.
Compile all other 32 vendor Swift files and `UI/FMTheseusTabBar.swift` into the
same FontManager module. Same-file private access is deliberately confined to
the generated extension; there is no runtime KVC, reflection, swizzling or
recursive inspection of Theseus private view hierarchies.

The Objective-C controller declares the narrow `FMTheseusTabBar` interface
explicitly. No generated `FontManager-Swift.h` import is needed. Exact runtime
selectors: `initWithTitles:`, `selectionHandler`, `selectedIndex`, and
`setSelectedIndex:animated:`.

The separately owned build wiring supplies the SwiftPM-equivalent
`Bundle.module` shim, Metal resource bundle `Theseus_Theseus.bundle` containing
`default.metallib`, framework linkage, Swift runtime linkage and resource
copy-before-sign ordering. Do not add a second Bundle.module implementation.
Package the upstream LICENSE and NOTICE with distributed products.

## Transparency, sampling and lifecycle

The actual body container clips to its continuous capsule; glass layers and
the moving lens use clear non-opaque backgrounds and capsule clipping.
Upstream `TheseusView` already sets CAMetalLayer.isOpaque=false and its render
pass clears RGBA to zero; those original files remain byte-for-byte intact.
There is no app-level filled UIButtonConfiguration, opaque white backing,
or rectangle surrounding the host.

Base and selection sampling explicitly use the real window, excluding the
host (including all its glyphs) and later foreground siblings along public
ancestry (bounded to 32 ancestors). The original lens intentionally captures
the bar's composed glass/items through its capture-twin machinery; its extra
exclusions omit that host so the optical chain is preserved and exclude later
foreground siblings. No arbitrary private hierarchy traversal is performed.

A weak-target common-mode 30Hz display link invalidates the real bar during
scrolling. It checks ancestor hidden/alpha state, window intersection and app
activity. Hidden/offscreen glass renderers pause; any ancestor-hosted lens is
torn down once on invisibility. Detaching invalidates the bridge display link;
backgrounding pauses it, activation resumes it. A visible bar still refreshes
at 30Hz while idle; device power measurement and idle-rate tuning are pending.
The upstream lens has its own original animation cadence.

## Checks and limits

Performed without building or pushing: generator executes successfully on the
pinned input, vendor byte comparison against downloaded commit, manifest hash
verification, negative tampered-input rejection, retained outer-constraint and
routing comparison, and `git diff --check`.

No native Swift/ObjC/Metal build, link, device rendering, performance, VoiceOver,
Reduce Motion, Reduce Transparency or drag/rotation acceptance test was run.
These require the parent's separately authorized build/device workflow. The
upstream automatically chooses its own capability/accessibility fallback;
MarkFont does not substitute an imitation glass implementation.
