# MarkFont: direct upstream Theseus integration

Theseus is pinned to `71ca1c127a4e7fe3387361f160c4890dbd427f66` from
https://github.com/valzevul/Theseus. All 37 upstream files retain their original
bytes. `vendor/Theseus/UPSTREAM.json` records their hashes; the build verifier
also pins the hash manifest itself.

## Actual compiler inputs

`app/Makefile` compiles all 33 Swift files directly from
`vendor/Theseus/Sources/Theseus`, including `TheseusTabBar`, `TheseusView`,
`TheseusRenderer` and `CaptureCompensation`. No source replacement or appended
extension is generated. The Metal shader also compiles directly from upstream.
The retired source-rewriting scripts and derivative-specific tests are removed.
Stale generated control files are never part of the compiler input list.

The only generated Swift source is `TheseusBundle.swift`. It supplies the
`Bundle.module` lookup normally synthesized by SwiftPM, pointing to the packaged
`Theseus_Theseus.bundle`. It contains no rendering or control implementation.
License and notice resources continue to accompany the bundle.

## MarkFont wiring

`FMTheseusTabBar.swift` is a separate Objective-C-visible UIView wrapper. It
provides the four existing destinations (挂载 / 字体 / 字体库 / 设置), their icons
(link / Aa / books.vertical / gearshape), initial selection 1 and the selection
callback. Programmatic selection uses upstream's public `selectedIndex` setter;
upstream owns its animation. The Objective-C selector keeps its existing
`animated:` argument for caller compatibility, without overriding upstream.

The wrapper forwards upstream's intrinsicContentSize and gives the child its
bounds. It does not override barHeight, preferredItemWidth, pill/lens dimensions,
material, tint, masks, capture source, capture exclusions, renderer lifecycle or
frame cadence. It adds no display link or application-state observer.

The parent places the original control horizontally centered, 14pt above the
bottom safe area, with at least 16pt clearance from either screen edge. There is
no fixed 72pt height or full-width stretch. Original defaults determine size:
barHeight 63pt and preferredItemWidth 66pt; mode-specific capsule and lens sizing
remain entirely upstream. On an unconstrained four-item iOS 27-style bar the
intrinsic size is 264 x 63pt; iOS 26 keeps upstream's width scaling.

All earlier MarkFont rendering adaptations are removed, including the optical
masks, padded-frame/capture-region rewrites, snapshot substitutions, feedback
exclusions, forced lens display, prewarm and teardown modifications. Upstream's
own stationary selection, interactive lens, shadows, gestures and fallback
policies remain as shipped.

## Checks

Run without compiling or dispatching a workflow:

```sh
python3 scripts/verify-theseus-upstream.py
python3 tests/theseus-upstream/check.py
```

The checks verify pinned source bytes, reject source/manifest tampering, evaluate
the real Makefile using include stubs for both package schemes, and assert that
all 33 original Swift files plus the wrapper and resource shim are the only
Swift inputs. They also insert stale generated controls in a temporary directory
and confirm those files cannot enter the input list.

These checks establish source identity and build wiring, not device appearance.
Native Swift/Metal compilation and on-device rendering of this direct-upstream
revision require a separately authorized build and subsequent device testing.
Earlier c972890/04d1b7d installation packages contain derivatives and do not
represent this revision. No claim is made that source identity alone resolves
the reported gray appearance or rectangular artifacts on the user's device.
