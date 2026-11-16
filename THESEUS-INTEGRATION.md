# MarkFont Theseus bottom bar

MarkFont uses the original upstream `TheseusTabBar`, including its internal
selection slider/material, lens optics, capture twins, vibrant tint, item
metrics, corner treatment, gestures and animation implementations. The original
press lift and lens excursion may extend beyond the host. The host does not clip.

## Pinned upstream and minimal extension

- Repository: https://github.com/valzevul/Theseus
- Revision: `71ca1c127a4e7fe3387361f160c4890dbd427f66`
- Location: `vendor/Theseus`; all 37 files match `UPSTREAM.json` SHA-256s.
- Original tab-bar SHA-256:
  `20e29ef46313b5a96daea9b1146ce7726a392a91795c1d574b998fe22509d921`.

`app/UI/prepare_theseus_tabbar.py` verifies the pinned SHA-256, then emits a
banner, the exact complete original source bytes, and a same-file extension.
It performs no substitutions in the original implementation. The extension
only adds programmatic index selection with explicit animation control and
host lifecycle/base-capture synchronization. Private access is confined to this
appended same-file extension. There is no `FMTheseusLensView` subclass.

## Application geometry and content

The controller retains its outer leading 16pt, trailing -16pt, safe-area bottom
-14pt and height 72pt constraints. The bridge uses public `barHeight = 72` and a
generous public `preferredItemWidth` to fill the available width. These describe
the outer layout, not a forced internal slider or body size. The original iOS26
optical mode can render a 62pt visible platter; original mode-dependent outsets,
selection geometry, typography, lens sizing and lift remain intact. There is no
64pt clamp, local lens host, added capsule mask or lift suppression.

The four localized titles remain 挂载 / 字体 / 字体库 / 设置 with link, Aa,
books.vertical and gearshape icons. Aa remains a 17pt heavy glyph rendered into
a transparent template. Original selected `.systemBlue`, native unselected tint
and `vibrantTint` behavior are retained. Initial selection remains index 1.
Existing controller routing, page swipes, pushed-page back behavior and bottom
safe-area reservation remain intact. The original accessible item views are used.

## Build contract

`app/Makefile` synchronously prepares the tab-bar adaptation and `Bundle.module`
shim before including Theos `application.mk`. Theos enumerates Swift inputs and
checks `__USER_FILES` in its own `before-FontManager-all::` recipe; a separate
same-name double-colon rule cannot order generation ahead of that check.
The checked `$(shell ...)` status stops make during parsing if either generator
fails, even when stale output exists. Direct developer make needs no wrapper.
Pure `clean`, `internal-clean` and `after-clean` invocations skip preparation.

Both Swift files use fixed architecture-independent paths under
`.theos/markfont-theseus/<scheme>/generated/`. Generators publish complete files
atomically and leave unchanged content timestamps intact across recursive
arm64/arm64e passes. Preparation only runs Python and Bash; Metal compilation
and resource/license copying retain their existing resource-target ordering
and per-architecture bundle paths. Make parsing (including `make -n`) may
prepare these Swift files; it does not compile them.

To run only the tab-bar generator manually, run from `app`:

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

## Sampling and lifecycle

The base background and resting-selection surfaces sample the real window,
excluding the host and later foreground siblings along public ancestry, bounded
to 32 ancestors. This is configured only on active host transitions. The moving
lens retains the original source, capture chain, container ownership, rendering
lifecycle and corner treatment; synchronization never reconfigures it each tick.

A weak-target common-mode 30Hz bridge display link refreshes the real backdrop
while visible, including during page scrolling. Host state accounts for ancestor
hidden/alpha state, window intersection and application activity. Only a state
transition invokes synchronization: inactivity tears down the original lens,
resets adaptation and pauses the two base renderers; activation resumes only the
base renderers. Upstream retains ownership of lens creation and resume/pause.
Detaching invalidates the bridge display link, backgrounding pauses it, and
activation resumes host visibility checks. Idle power tuning remains pending.

## Validation and limits

Restoration checks cover exact original-source prefix equality after the banner,
all 37 vendor SHA-256s, tampered-input rejection, unchanged outer constraints,
Objective-C syntax for arm64 and arm64e, and whitespace validation. Remote
synchronization verifies the complete source tree's blob hashes and file modes.

No native Swift/Metal build, link, device rendering, performance, VoiceOver,
Reduce Motion, Reduce Transparency or drag/rotation acceptance test is claimed.
No build or workflow dispatch is part of this restoration. The existing build
contract above is retained; original capability/accessibility fallbacks remain
under upstream control.
