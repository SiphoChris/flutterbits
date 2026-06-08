# tweakcn → `theme.dart` generator — design

**Status:** approved design · **Date:** 2026-06-08 · **Home:** `apps/docs` (Next.js / TypeScript) ·
**Audience:** engineers building the generator and the G0 engine prereq.

This spec implements **AGENTS.md §7**. §7 is the contract; this document is the *how*. Where §7
and this spec ever disagree, §7 wins and this file is the drift (fix it). The headline product
capability is **theme portability** (§1): paste a [tweakcn](https://tweakcn.com)/shadcn theme, get a
working Flutter `theme.dart` with nothing dropped.

---

## 1. What it does

**Input:** a pasted tweakcn/shadcn theme — a CSS `:root { … }` block (light) and a `.dark { … }`
block (dark), each a set of `--token: value;` declarations.

**Output:** two downloadable files:
- `theme.json` — the **source of truth**. Its schema mirrors the `FwTokens` shape (32 colors +
  `radiusBase` + radii + 7 shadows + 3 font families + `tracking`). Fixed at build time.
- `theme.dart` — the **emitted artifact**: two `const FwTokens` (light + dark) against the §5
  contract, a drop-in file requiring **no edits** to component code, plus a clearly-commented
  `google_fonts` wiring stub for any named font.

The web UI (§7 below) is paste → auto-detect format → **hard-validate all 32 colors** → live
preview (swatches + radius + shadow samples, light & dark) → download both files, with a
faithful/perceptual conversion toggle.

**Out of scope for this feature (recorded, not silently dropped):** the §2 "registry endpoint"
that will also live in `apps/docs`. It pairs with the not-yet-built `flutterbits_cli`/`registry`
and is a sibling track, built when those land. This feature is *only* the theme generator.

---

## 2. Architecture

A **pure-TS staged pipeline** under `apps/docs/src/lib/generator/`, with a thin React route on top.
Each stage is a pure function, independently unit-tested:

```
paste (raw CSS text)
  │
  ▼  parse/            tolerant tokenizer of :root + .dark
RawTheme  { root: RawBlock, dark: RawBlock }   // token strings, verbatim; unknown vars recorded
  │
  ▼  color/            oklch│hsl│rgb│hex  →  sRGB 8-bit (ARGB)
ResolvedTheme  { light: ResolvedBlock, dark: ResolvedBlock }
  │
  ▼  emit/             ResolvedTheme  →  ThemeJson  →  theme.dart string
{ themeJson, dartSource }
```

**Module layout:**

```
apps/docs/src/lib/generator/
  color/            # G1 — format parsers + OKLCH→sRGB conversion + clip / opt-in gamut-map
  parse/            # G2 — CSS :root/.dark → RawTheme
  emit/             # G3 — ResolvedTheme → ThemeJson → theme.dart
  types.ts          # RawTheme, ResolvedTheme, ThemeJson, token-name contract
  __fixtures__/     # claude.css (the golden), oklch vectors, parser edge cases
apps/docs/src/app/(home)/theme-generator/   # G4 — the route + UI components
apps/docs/content/docs/theme-generator.mdx  # G5 — docs page
```

**Why this shape:** §7 mandates that color math live *only* here (the Dart CLI never generates
themes) and that `theme.json` be the source of truth. Strict `parse → color → emit` with
`ThemeJson` as the pivot makes that invariant testable: `theme.dart` is a pure function of
`theme.json`, and every schema field is consumed (S3 test below).

### 2.1 Color math: hand-rolled, zero-dependency

The conversion is hand-rolled (no `culori` / color lib). The honest reason (per §12, restate in
G5 docs): we need **a specific, documented gamut-clip we control and can vector-test against the
baked Tailwind hex** — a general color library would make the clip strategy *opaque*, not wrong,
and adds a runtime dep to a published artifact for ~80 lines of well-specified math.

Pipeline (§7): `OKLCH → OKLab → LMS → linear sRGB → gamma-encode → sRGB`.

- **Default = faithful-clip.** Gamut-*clip* the linear-sRGB channels to `[0,1]` so output matches
  Tailwind's published hex (`FwPalette`) by construction. For the realistic shadcn/Tailwind
  in-gamut range this is exact; the clip only bites for vivid out-of-gamut colors.
- **Opt-in = perceptual.** Hue-preserving **chroma reduction** (binary-search chroma down until
  in-gamut) instead of clipping, for extreme out-of-gamut colors / a display-P3 target. This is
  where the wider-gamut target lives. Toggle in the UI; default off.

**Input formats (all four required, §7):** `oklch()`, `hsl()`, `rgb()`/`rgba()`, hex (`#rgb`,
`#rrggbb`, `#rrggbbaa`). Each must accept:
- the **alpha slash-syntax** — `oklch(L C H / 0.1)`, `hsl(H S% L% / 10%)`, `rgb(r g b / 0.5)` — and
  carry it into the ARGB alpha byte. This is how dark-mode `border`/`input` get translucency
  (e.g. stock dark `border` = `white/10%` = `0x1AFFFFFF`). **Not optional** — dropping it silently
  loses real tokens.
- **both lightness forms** for OKLCH: unit (`oklch(0.62 …)`) and percent (`oklch(62% …)`).

---

## 3. The emit target (what `theme.dart` must contain)

Two `const FwTokens`. Field-for-field against the engine types
(`packages/flutterwindcss/lib/src/tokens/`):

- **`colors: FwColors(...)`** — **all 32**, mapped directly from CSS names: the 19 core +
  `chart1…chart5` (`--chart-1`→`chart1`) + the 8 `sidebar*` (`--sidebar-foreground`→
  `sidebarForeground`). `FwColors`'s `const` ctor has **no defaults** — omitting any color means
  `theme.dart` won't compile. The generator never relies on that downstream; it **hard-gates**
  before emit (S6).
- **`radiusBase: <px>`** and **`radii: FwRadii(base:, sm:, md:, lg:, xl:)`** — explicit additive
  derivation from `--radius` (§4.1). **Never** `FwRadii.fromBase`.
- **`shadows: FwShadows(xs2:, xs:, sm:, md:, lg:, xl:, xl2:)`** — 7 slots from `--shadow-*` (§4.2).
- **`typography: FwTypographyTheme(sans:, serif:, mono:, tracking:)`** — family names + `tracking`
  (§4.3, requires the G0 engine change).

`theme.json` carries the same data in a fixed JSON schema (§4.4).

---

## 4. Per-domain emit rules

### 4.1 Radius — explicit additive

shadcn derives the set **additively** from `--radius`:
`sm = r − 4px`, `md = r − 2px`, `lg = r`, `xl = r + 4px` (px after rem→px at 16px root).

Emit an **explicit** `FwRadii(base: r, sm: r−4, md: r−2, lg: r, xl: r+4)`. Do **not** use
`FwRadii.fromBase` — its `×0.6/0.8/1.0/1.4` factors coincide with the additive set *only* at the
10px default and diverge for any other base. `_claudeRadii` in `themes.dart` (base 16 → 12/14/16/20)
is the worked reference.

> **Regression guard (S4):** an emitter test at a **non-10** base — `--radius: 0.5rem` (8px) →
> `FwRadii(base: 8, sm: 4, md: 6, lg: 8, xl: 12)` — asserts the emitted Dart is exactly that and
> is **not** `fromBase(8)` (which would give sm 4.8 / md 6.4 / xl 11.2).

### 4.2 Shadows — 7 slots + the default, from the composed strings

Emit `FwShadows{xs2, xs, sm, md, lg, xl, xl2}` from `--shadow-2xs … --shadow-2xl`. The **unprefixed
`--shadow`** (and `shadow-DEFAULT`) maps onto **`md`**.

**Authoritative source = the composed `--shadow-*` strings.** tweakcn also emits the per-axis
builder *inputs* (`--shadow-x/y/blur/spread/opacity/color`); these **bake into** the composed
strings and are **not** separate outputs. The parser reads the composed `--shadow-*` and **ignores**
the per-axis primitives (assert this in G2).

**CSS shadow string → `BoxShadow` transform.** A CSS box-shadow is
`<offset-x> <offset-y> <blur> <spread> <color>` (multiple comma-separated layers allowed):
- `offset-x/y` (px) → `Offset(x, y)`
- `blur` (px) → `blurRadius`
- `spread` (px, optional, default 0) → `spreadRadius`
- color → `Color` (parsed via the §2.1 color core, alpha-aware)
- multiple layers → a `List<BoxShadow>` in source order.

> **Oracle decision (B2):** `_claudeShadows` in `themes.dart` is a hand-transcription, **not** the
> canonical output of this transform. At G3 we run the real Claude CSS through the transform and
> **replace `_claudeShadows` with the generator's output** in the same PR (with a
> `// corrected — generator` note and a §12 drift line), making `themes.dart` a faithful oracle.
> The end-to-end golden then asserts the **full bundle** (colors + radii + shadows + type), not
> colors alone — narrowing it to colors is a §12 silent-scope failure and is disallowed.

### 4.3 Typography — families + `tracking` (requires G0)

Emit `FwTypographyTheme(sans:, serif:, mono:, tracking:)`:
- **Families:** the `--font-sans`/`--font-serif`/`--font-mono` *names*. The generator emits the name
  **and** a clearly-commented `google_fonts` wiring stub. It MUST NOT pretend to bundle a font; an
  unknown family gets a `// TODO: bundle this font or map it` comment, never a silent fallback.
- **`tracking`:** from `--tracking-normal`. tweakcn expresses it in **em** (e.g. `-0.025em`); we
  store the **em value as a `double`** on `FwTypographyTheme.tracking`. Conversion to Flutter's
  logical-px `letterSpacing` (em × font-size) happens at the text-apply site, **not** in the token.

> **`--spacing` (knowing drop, §7):** flutterwindcss's spacing scale is a fixed `1 unit = 4px`
> (`fwSpace`), context-free by design. A non-default `--spacing` is dropped **knowingly** with an
> emitted comment noting it. Not silently lost.

> **Recorded follow-on (not this feature):** wiring `tracking` em×fontSize → `letterSpacing` on the
> engine's `DefaultTextStyle` render path. Mechanism is known (a theme-resolved `letterSpacing` in
> the typography apply step); descoped from G0 by decision so G0 stays tight. The token round-trips
> and interpolates regardless.

### 4.4 `theme.json` schema (source of truth)

Fixed at build time. Shape mirrors `FwTokens`:

```jsonc
{
  "radiusBase": 16,
  "radii":  { "base": 16, "sm": 12, "md": 14, "lg": 16, "xl": 20 },
  "colors": { "light": { /* 32 named hex/argb */ }, "dark": { /* 32 */ } },
  "shadows": { /* 7 slots, each a list of {color, x, y, blur, spread} */ },
  "typography": { "sans": "Outfit", "serif": "Georgia", "mono": "Geist Mono", "tracking": -0.025 },
  "meta": { "conversion": "faithful" | "perceptual", "droppedVars": [ /* recorded unknowns */ ] }
}
```

`emit/` is strictly `ResolvedTheme → ThemeJson → dartSource`. A test asserts `emitDart(themeJson)`
consumes **every** schema field (S3) — so "json is source of truth" is structural, not cosmetic.

---

## 5. G0 — engine prereq: `tracking` on `FwTypographyTheme`

A small, coordinated Dart change so the emit target exists. In
`packages/flutterwindcss/lib/src/tokens/typography.dart` (and `tokens.dart`):

- Add `final double tracking;` to `FwTypographyTheme` (constructor param, default `0`), with a
  `///` doc explaining units are **em**.
- Add it to `==` and `hashCode`.
- **Add `FwTypographyTheme.lerp(a, b, t)`**: hard-crossover the three family-name strings (they
  can't numerically interpolate — same rationale as the existing `FwTokens.lerp` typography
  crossover), and **numerically lerp `tracking`**. This is the point of "lerp-able."
- **Rewire `FwTokens.lerp`** (`tokens.dart`) to call `FwTypographyTheme.lerp(a.typography,
  b.typography, t)` instead of the current `t < 0.5 ? a.typography : b.typography` hard crossover —
  otherwise `tracking` snaps instead of interpolating, defeating the field.
- `FwTokens.light`/`dark` and `FwTypographyTheme.standard` are **unchanged** (default `tracking: 0`
  preserves current behavior and all existing goldens).

**Drift sweep (same PR, §12):** fix `radii.dart`'s now-misleading `/// Prefer FwRadii.fromBase.`
doc-comment (it actively misleads the generator author — clarify that `fromBase` is for stock
×-factor themes and explicit `FwRadii(...)` is required for additive/generated themes); update the
`FwTypographyTheme` doc-comment to mention `tracking`; sweep §5/§7 of AGENTS.md and the README for
any statement the new field falsifies.

---

## 6. Module decomposition (one branch → PR → `gh` merge each)

Ordered **G0 → G1 → G2 → G3 → G4 → G5** (the emitter needs the color core *and* the `tracking`
field; the UI needs the full pipeline).

| Module | Scope | Done when |
|---|---|---|
| **G0** | Engine: `tracking` field + `FwTypographyTheme.lerp` + `FwTokens.lerp` rewire + drift sweep | Dart analyze/format clean; existing goldens unchanged; new lerp unit test (tracking interpolates, families crossover) green |
| **G1** | `color/`: 4 format parsers (alpha + both L forms) + OKLCH→sRGB convert + faithful-clip + opt-in chroma-reduction gamut-map | Vector fixtures pass (incl. **real OKLCH-source → baked-hex**, B1); alpha + percent-L cases covered |
| **G2** | `parse/`: tolerant `:root`/`.dark` tokenizer → `RawTheme`; records unknown vars; ignores per-axis `--shadow-*` primitives; flags missing required tokens | Parser fixtures pass (messy whitespace, comments, all 4 formats, missing-token, alpha syntax) |
| **G3** | `emit/`: `ResolvedTheme → ThemeJson → theme.dart`; additive radius, shadow transform, font stub, `tracking`, `--spacing` drop-comment; **regenerate `_claudeShadows`** | ThemeJson schema snapshot + `emitDart` totality test (S3) + non-10 radius guard (S4); **e2e golden (full bundle) vs `themes.dart`** green |
| **G4** | Route + UI: paste → auto-detect → **hard-gate 32 colors** → preview (swatch/radius/shadow, light+dark) → download both + faithful/perceptual toggle | Manual run renders the Claude theme; missing-token gate refuses download with a listed error |
| **G5** | Docs MDX page (usage, limitations, the `--spacing`/font caveats) + full drift sweep of §7/README/roadmap | Docs accurate; no doc contradicts code |

---

## 7. Web UI (G4)

Single route. Behavior:
1. **Paste** a `:root` + `.dark` block into a textarea.
2. **Auto-detect** each value's format per declaration (formats can mix within a theme).
3. **Hard-validate** all 32 colors per block. Missing any → **block download**, show the exact list
   of missing tokens. Rationale (S6): `FwColors` has no defaults, so a partial `theme.dart` won't
   compile — but a web user has no compiler, so we refuse at generate-time with a clear message
   rather than hand them a broken file.
4. **Preview** (read-only, light + dark side-by-side): a swatch grid of the 32 colors, the four
   radius samples, and the 7 shadow samples. (No mock-component preview — an HTML approximation of
   Flutter rendering would mislead.)
5. **Conversion toggle:** faithful-clip (default) ↔ perceptual gamut-map.
6. **Download** `theme.dart` and `theme.json`.

---

## 8. Testing (§9 — mandatory)

The whole proof rests on **not** validating the generator against artifacts that were themselves
hand-produced without the generator's math. Layers:

- **Color core (G1):**
  - **Real OKLCH-source → baked-hex vectors (B1, the keystone):** take Tailwind v4's *source*
    `oklch()` definitions for ~12 swatches and assert the pipeline reproduces the **exact** hex
    already in `palette.g.dart`. This is the only test that proves "faithful"; the palette JSON
    alone (hex-only) would just exercise the hex parser (circular).
  - Per-channel matrix vectors (math internal-consistency), alpha-syntax cases, percent-vs-unit L,
    all four formats, and a handful of out-of-gamut colors showing clip ≠ gamut-map.
  - **Stock chart/sidebar agreement (S1):** add the stock shadcn `chart*`/`sidebar*` OKLCH sources
    to the vector set and assert they reproduce the `tokens.dart` baked hex. If a vivid one (e.g.
    `chart4`/`chart5` oranges) doesn't match under clip, that's a real finding — surface it, don't
    quietly retune a literal.
- **Parser (G2):** fixtures for messy whitespace/comments, all four formats, alpha syntax, missing
  tokens (→ recorded), and presence of per-axis `--shadow-*` primitives (→ ignored, composed string
  wins).
- **Emitter (G3):** `ThemeJson` schema snapshot; `emitDart(themeJson)` totality (every field
  consumed, S3); non-10 radius guard (S4).
- **End-to-end golden (G3):** the **real pasted Claude CSS** (committed as
  `__fixtures__/claude.css`) → emit → assert the **full bundle** — 32 colors *and* radii *and*
  shadows *and* typography — equals `themes.dart`'s `_claudeLight`/`_claudeDark`/`_claudeRadii`/
  `_claudeShadows`/`_claudeType`. Expected values are transcribed into a TS fixture that **mirrors**
  `themes.dart` (which is the human-checked source of those values; noted in the fixture header).
  Shadows are asserted after the G3 regeneration step makes `_claudeShadows` faithful (§4.2).

> **Input needed at G3:** the exact `:root`/`.dark` CSS the Claude theme was transcribed from
> (user provides). Committed verbatim as the golden fixture.

---

## 9. Risks & honest calls

- **No OKLCH inputs in-repo** → the faithfulness proof depends on externally-sourced Tailwind v4
  `oklch()` definitions (public). Mitigated by the B1 vector fixture; flagged so the dependency is
  explicit, not hidden.
- **`themes.dart` shadows currently diverge** from the canonical transform → resolved by
  regenerating them at G3 (decision recorded, §4.2), not by narrowing the test.
- **`tracking` is stored but not yet applied to rendered text** → recorded follow-on with mechanism
  (§4.3); the token still round-trips and interpolates, satisfying §7.
- **Perceptual gamut-map** is opt-in and lower-traffic → covered by clip≠map vectors, not a full
  golden; acceptable since faithful-clip is the default and the realistic shadcn range is in-gamut.

Nothing here is refused on cost grounds; every domain (color, radius, shadow, type) is emitted in
full per §7.
