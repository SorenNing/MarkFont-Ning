# Third-Party Notices

MarkFont's isolated bindfs backend uses the public `libjailbreak` client API
and follows the credential-borrowing integration pattern documented by the
Dopamine project.

## Dopamine

MIT License

Copyright (c) 2023-2024 Lars Fröder (opa334)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Theseus

Theseus — Copyright 2025 Vadim Drobinin.

This product includes software developed by Vadim Drobinin
(https://drobinin.com).

Source: https://github.com/valzevul/Theseus

Pinned revision: `71ca1c127a4e7fe3387361f160c4890dbd427f66`.
Licensed under the Apache License, Version 2.0. The complete upstream license
and attribution notice are retained in `vendor/Theseus/LICENSE` and
`vendor/Theseus/NOTICE`; `vendor/Theseus/UPSTREAM.json` records file SHA-256s.

Vendor files remain byte-for-byte upstream. At build time MarkFont's
`app/UI/prepare_theseus_tabbar.py` and `app/UI/theseus_geometry.py` verify pinned
inputs and emit derivatives of TheseusTabBar, TheseusView, TheseusRenderer and
CaptureCompensation outside vendor. Changes adapt slot/lens geometry, transparent
Metal host extent, capture coordinates, rounded capture-only replacements,
transactional capture swaps and moving-lens feedback exclusions. Original shader,
material/color/refraction parameters and gesture springs are retained. The tab-bar
derivative appends programmatic selection and lifecycle bridging. These generated
files are modified derivatives, not byte-identical upstream implementations.
See `THESEUS-INTEGRATION.md`.
