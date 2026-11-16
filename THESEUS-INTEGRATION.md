# MarkFont Theseus bottom bar

Theseus upstream is pinned to `71ca1c127a4e7fe3387361f160c4890dbd427f66`
from https://github.com/valzevul/Theseus. All 37 vendor files remain pristine;
`vendor/Theseus/UPSTREAM.json` contains their SHA-256s. Original shaders,
material presets, theme colors, tint, blur and refraction parameters are retained.
Generated implementations are geometry/capture derivatives, not exact original
source prefixes. LICENSE and NOTICE must accompany distributions.

## Geometry

The Objective-C controller keeps leading/trailing 16pt, safe-area bottom 14pt
and height 72pt constraints. Four equal slots span the actual content width.
Resting selection and moving lens use slot width minus 8pt and height 64pt,
centered in their slot (4pt inset). Both optical modes use this geometry; their
old fixed 74/80pt pills and 90/96x70pt lenses no longer determine live sizing.
Mode-dependent chrome offsets are compensated geometrically so the visible body
fills the 72pt outer bar. The extra 0.8pt moving-lens outset is removed.

Original gesture recognition, lift, follow, stretch and morph springs remain.
Requested drag centers stop at the first/last slot center; the original 7.2pt
end overrun no longer pushes the lens past its edge slot. Dynamic lift/stretch
and optical shadows still extend beyond their resting frame. The host is not
blanket-clipped: this preserves original optical output and does not promise a
strict 64pt screen-space height during press animations.

Localized titles remain 挂载 / 字体 / 字体库 / 设置; icons remain link / Aa /
books.vertical / gearshape. Aa is a transparent 17pt heavy template. Initial
selection remains index 1; original selected/unselected and vibrant tints remain.

## Captures and rectangular artifacts

The supplied video montage visibly contains rectangular translucent panels and
ghost glyphs during movement. Source inspection found independent concrete faults:

- MetalLayerView defaulted to opaque and its frame stayed at unpadded bounds,
  while its drawable included drawPadding. The derivative explicitly makes the
  host transparent and sizes its frame to bounds expanded by drawPadding.
- Snapshot frame and renderer capture region now use that already-padded extent
  directly, through coordinate conversion, without a second expansion. Shader
  padding uniforms and drawable pixel dimensions still include padding once.
- Resizing invalidates snapshots/overrides; readbacks with obsolete dimensions
  are rejected instead of stretching an old image into the new frame.
- CaptureCompensation no longer paints a rectangular glass.backgroundColor when
  a snapshot is unavailable. It adds a temporary rounded, shape-inset-aware layer
  with the original captureVeilColor. Actual snapshot replacement layers retain
  their original alpha, full padded frame and chrome override; no new mask is
  applied to real snapshots. Live Metal also remains unmasked with original
  shader alpha, shadows and material.
- A hidden Metal host is skipped rather than replaced by a stale frame/veil.
  Capture begin/end and renderer twin swaps use disabled-action transactions,
  with defer restoration in the same render call, including early exits.
- The ancestor-owned moving lens is weakly excluded from both base captures.
  Excluding only the bar subtree could not exclude this root sibling and could
  feed its previous glyphs back into the background/resting selection.

The hidden capture-twin row is still hidden; its glyphs are drawn only into the
original explicit item layer. Their show/hide lifecycle is retained. These fixes
address identified source defects, not a claim of device-proven visual resolution.

## User build configuration

Use the existing Theos application target, Swift 5 and the project's arm64/arm64e
configuration. `app/Makefile` prepares Swift sources synchronously before
`application.mk`; no CI dispatch is needed. Python 3 and Bash are required.
The ordinary developer make command regenerates sources automatically. Pure
clean targets skip generation. Generators atomically publish files and preserve
unchanged timestamps across recursive architecture passes.

Manual preparation, from repository root:

```sh
python3 app/UI/prepare_theseus_tabbar.py \
  vendor/Theseus/Sources/Theseus/Components/TheseusTabBar.swift \
  /tmp/markfont-theseus/TheseusTabBar.swift
python3 tests/theseus-geometry/check.py
```

The generator verifies pinned hashes and emits four derived Swift inputs beside
the chosen output: TheseusTabBar.swift, TheseusView.swift, TheseusRenderer.swift,
CaptureCompensation.swift. Compile these INSTEAD OF their four vendor equivalents;
compile remaining vendor Swift, FMTheseusTabBar.swift and the existing generated
Bundle.module shim into the SAME FontManager module. The Makefile handles this
exclusion. Do not compile duplicate classes or add another Bundle.module shim.

The existing Metal target compiles pristine TheseusShaders.metal into
Theseus_Theseus.bundle/default.metallib. UIKit, QuartzCore, CoreText,
UniformTypeIdentifiers, CoreGraphics, Metal, MetalKit, IOSurface, CoreVideo and
Accelerate linkage, Swift runtime search paths, resource copying and license
packaging retain existing wiring. This work does not compile or package a binary.

Objective-C calls the explicit bridge selectors initWithTitles:,
setSelectedIndex:animated:, selectionHandler and selectedIndex. The weak-target
30Hz common-mode display link refreshes while visible; activation resumes base
renderers and inactivity tears down the moving lens and pauses the base pair.

## Validation limits

Local checks verify all vendor hashes, deterministic generation, tamper rejection,
four source substitutions, unchanged material/shader expressions, geometric
inset/drag/capture calculations over multiple sizes and scales, and unchanged
outer constraints. Objective-C controller syntax is checked for arm64 and arm64e
with the local iPhoneOS SDK. No native Swift compiler is available in this shell;
Swift type checking, Metal build/link and device acceptance are still required.

Device acceptance must include repeated dragging, tap/morph handoff, narrow and
wide layout changes, light/dark optical modes, scrolling, app visibility changes
and transparency/accessibility fallbacks. Original dynamic animation geometry
remains capable of exceeding the resting bounds: 64 * 1.1 * 1.0431 is about
73.43pt, and the 72pt body under lift alone is about 75.10pt. End-center clamping
prevents the removed explicit 7.2pt overrun, but is not a blanket containment
claim for transformed geometry or optical shadows. No performance, VoiceOver or
device-level disappearance of every artifact is claimed.
