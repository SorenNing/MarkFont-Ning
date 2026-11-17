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

All 33 upstream Swift files and the Metal shader are compiled directly from
`vendor/Theseus/Sources/Theseus`, byte-for-byte as pinned above. No control,
renderer, capture or geometry derivatives are generated. MarkFont's separate
Objective-C-visible wrapper supplies four destinations and positions the control
through public API. The only generated Swift source supplies `Bundle.module`
resource lookup for this non-SwiftPM build. Upstream LICENSE and NOTICE accompany
the resource bundle. See `THESEUS-INTEGRATION.md`.
