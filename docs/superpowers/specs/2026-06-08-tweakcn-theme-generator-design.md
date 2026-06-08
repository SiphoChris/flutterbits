# tweakcn → `theme.dart` generator — design

**Status:** approved design · **Date:** 2026-06-08 · **Home:** `apps/docs` (Next.js / TypeScript) ·
**Audience:** engineers building the generator and the G0 engine prereq.

This spec implements **AGENTS.md §7**. §7 is the contract; this document is the *how*. Where §7
and this spec ever disagree, §7 wins and this file is the drift (fix it). The headline product
capability is **theme portability** (§1): paste a [tweakcn](https://tweakcn.com)/shadcn theme, get a
working Flutter `theme.dart` with nothing dropped.

---

## 1. What it does

**Input:** a pasted tweakcn/shadcn theme — the **entire** CSS file as exported from tweakcn. tweakcn
exports the **same theme in any of four color formats** (the user picks the export format), so the
generator must accept all four interchangeably. The repo carries the *identical* Claude theme in all
four as golden fixtures: `__fixtures__/claude.{hex,rgb,hsl,oklch}.css`. Each file contains far more
than the two blocks we read: a `@import "tailwindcss";` line, a `@custom-variant dark (…)`, a
`:root { … }` block (light), a `.dark { … }` block (dark), a `@theme inline { … }` block (Tailwind's
var→utility mapping, all `var()`/`calc()` indirection), and a `@layer base { … }` block. **We read
values only from the `:root` and `.dark` blocks** and ignore everything else (§2.2). URL input
(paste a tweakcn share link, fetch the CSS) is a recorded possible enhancement, not v1.

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
  __fixtures__/     # claude.{hex,rgb,hsl,oklch}.css (the goldens), oklch clip vectors, parser edge cases
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

**Why faithful-clip is the default (the "oklch debate," §7 / engine spec §4.1).** The original
policy was "always gamut-map"; it was corrected to **faithful-clip default, gamut-map opt-in**
because coherence with the recognizable Tailwind/shadcn hex matters more than matching
browser-rendered pixels for the realistic color range. The four-format fixtures *prove this is the
right default*: tweakcn's exported `oklch()` values are **already in-gamut sRGB projections**, not
the wild out-of-gamut Tailwind *source* values. Concretely — dark `destructive` is `#ef4444`
(Tailwind red-500) but its oklch export is `oklch(0.6368 0.2078 25.3313)`: chroma **0.2078**, the
value you get converting `#ef4444` *back* to oklch, **not** Tailwind's out-of-gamut source chroma
`0.237`. So under faithful-clip the clip barely engages and **all four formats converge** on the
same sRGB. (Gamut-map would *move* these already-correct colors and is therefore correctly opt-in.)

This makes the four-format fixtures the keystone color oracle: 32 authoritative `oklch → sRGB`
pairs from the exact tool we are cloning. Expected convergence (§8): **hex/rgb/hsl byte-exact** to
`themes.dart`; **oklch within ±1 per 8-bit channel** (floating-point vs culori rounding), with any
±1 channel investigated to confirm it is rounding, not a bug.

**Input formats (all four required, §7):** `oklch()`, `hsl()`, `rgb()`/`rgba()`, hex (`#rgb`,
`#rrggbb`, `#rrggbbaa`). Each must accept:
- the **alpha slash-syntax** — `oklch(L C H / 0.1)`, `hsl(H S% L% / 10%)`, `rgb(r g b / 0.5)` — and
  carry it into the ARGB alpha byte. This is how dark-mode `border`/`input` get translucency
  (e.g. stock dark `border` = `white/10%` = `0x1AFFFFFF`), and how shadow colors arrive
  (`hsl(0 0% 0% / 0.05)`). **Not optional** — dropping it silently loses real tokens.
- **both lightness forms** for OKLCH: unit (`oklch(0.62 …)`) and percent (`oklch(62% …)`).

Alpha → byte is **round-to-nearest** (verified against `_claudeShadows`: `0.05·255=12.75→0x0D`,
`0.10·255=25.5→0x1A`, `0.25·255=63.75→0x40`). Hex without an alpha pair is fully opaque (`#rrggbb`
→ `0xFFrrggbb`).

### 2.2 Input structure — what the parser reads and ignores (G2)

The tweakcn export is a full CSS file. The parser MUST be robust to all of it:

- **Extract only the `:root` and `.dark` rule blocks**, matched by selector and brace-balanced
  (handle nested `{ }`). Read each block's `--token: value;` declarations.
- **Ignore** `@import`, `@custom-variant`, `@theme inline { … }`, `@layer { … }`, and any other
  selector (`*`, `body`, …). In particular the `@theme inline` block re-declares `--color-*`,
  `--radius-sm/md/lg/xl`, and `--shadow-*` as `var()`/`calc()` indirection — these are **not**
  values and must not be read; the real values are in `:root`/`.dark`. (The `@theme inline`
  `--radius-*: calc(var(--radius) ± Npx)` lines *confirm* the additive derivation in §4.1, but we
  compute it from `--radius` ourselves rather than parsing the `calc()`.)
- **Beware false `.dark` matches.** `@custom-variant dark (&:is(.dark *));` contains the substring
  `.dark` but is **not** the `.dark` rule. Match a `.dark` *selector* immediately followed by `{`,
  not a bare substring.
- **Record, don't drop.** Any `--var` in `:root`/`.dark` we don't map (none in this theme beyond
  the handled set) goes into `meta.droppedVars` (§4.4), never silently discarded (§12).

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

> **Oracle decision (B2) — resolved by checking the real CSS:** the worry was that
> `_claudeShadows` (a hand-transcription) might diverge from the canonical transform. Running this
> theme's actual `--shadow-*` through the transform by hand reproduces all 7 slots of
> `_claudeShadows` **byte-for-byte** (`xs2`=`xs`=`[0x0D,(0,1),3]`; `sm`/`md`/`lg`/`xl` two-layer
> `0x1A`; `xl2`=`[0x40,(0,1),3]`). So the planned "regenerate" step is a **verified no-op** that
> *confirms* `themes.dart` as a faithful oracle rather than correcting it. The end-to-end golden
> still asserts the **full bundle** (colors + radii + shadows + type), not colors alone — narrowing
> it to colors is a §12 silent-scope failure and is disallowed. If a *future* theme's shadows ever
> diverge from a hand-authored oracle, the rule stands: fix the oracle to the transform's output,
> in-PR, with a `// corrected — generator` note (§12).

### 4.3 Typography — families + `tracking` (requires G0)

Emit `FwTypographyTheme(sans:, serif:, mono:, tracking:)`:
- **Families — extract one name from a CSS font *stack*.** The values are stacks, not single names:
  `--font-sans: Outfit, sans-serif`, `--font-serif: ui-serif, Georgia, Cambria, "Times New Roman",
  Times, serif`, `--font-mono: Geist Mono, ui-monospace, monospace`. The faithful rule (matching
  `themes.dart`'s `sans:'Outfit'`, **`serif:'Georgia'`**, `mono:'Geist Mono'`) is: **take the first
  family that is not a CSS generic keyword, with surrounding quotes stripped.** Generic keywords to
  skip: `serif, sans-serif, monospace, cursive, fantasy, system-ui, math, emoji, fangsong, ui-serif,
  ui-sans-serif, ui-monospace, ui-rounded`. (That is why serif resolves to `Georgia`, skipping the
  leading `ui-serif`.) If *every* entry is generic, keep the first. The generator emits the chosen
  name **and** a clearly-commented `google_fonts` wiring stub. It MUST NOT pretend to bundle a font;
  an unknown family gets a `// TODO: bundle this font or map it` comment, never a silent fallback.
- **`tracking`:** from `--tracking-normal`, read from **`:root`** (tweakcn puts it only there, not in
  `.dark`) and applied to **both** light and dark typography. tweakcn expresses it in **em** (this
  theme: `0em` → `0.0`; e.g. `-0.025em` → `-0.025`); we store the **em value as a `double`** on
  `FwTypographyTheme.tracking`. Conversion to Flutter's logical-px `letterSpacing` (em × font-size)
  happens at the text-apply site, **not** in the token. If `--tracking-normal` is absent, default
  `0`.

> **`--spacing` (knowing drop, §7):** flutterwindcss's spacing scale is a fixed `1 unit = 4px`
> (`fwSpace`), context-free by design. The drop-comment fires **only when `--spacing` ≠ the 4px
> default**. This theme's `--spacing: 0.25rem` *is* 4px, so no comment is emitted; a non-default
> value would emit a comment noting it was dropped (never silently lost). `--spacing`, like
> `--tracking-normal`, is read from `:root`.

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
| **G3** | `emit/`: `ResolvedTheme → ThemeJson → theme.dart`; additive radius, shadow transform, font-stack extraction, font stub, `tracking`, `--spacing` drop-comment; **verify `_claudeShadows` matches the transform** (it does — §4.2) | ThemeJson schema snapshot + `emitDart` totality test (S3) + non-10 radius guard (S4); **e2e golden (full bundle) vs `themes.dart`** green |
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
  - **Four-format convergence (the keystone, B1):** parse all four `claude.{hex,rgb,hsl,oklch}.css`
    fixtures and assert, per token, that **hex/rgb/hsl are byte-exact** to each other and to
    `themes.dart`, and **oklch is within ±1 per 8-bit channel** of them. This is 32 authoritative
    `oklch → sRGB` pairs from tweakcn/culori itself — a stronger faithfulness proof than synthetic
    vectors, and it directly exercises the full OKLCH→OKLab→linear→gamma→sRGB→clip path (the
    palette JSON alone is hex-only and would just test the hex parser — circular). Once G1 runs,
    pin the exact computed oklch ARGBs as a reviewed snapshot (each verified ≤1 from `themes.dart`)
    so the test is byte-tight going forward.
  - **Out-of-gamut clip vectors:** a handful of Tailwind v4 *source* `oklch()` values whose chroma
    is out of sRGB gamut (e.g. red-500 source `oklch(0.637 0.237 25.331)` → published `#ef4444`),
    asserting faithful-clip reproduces the published hex and that clip ≠ gamut-map there. (The
    four-format fixtures cover the in-gamut path; these cover the clip path the fixtures don't hit.)
  - Per-channel matrix vectors (math internal-consistency), alpha-syntax cases (`hsl(… / 0.10)`,
    `oklch(… / 0.1)`), and percent-vs-unit OKLCH lightness.
- **Parser (G2):** fixtures for messy whitespace/comments, all four formats, alpha syntax, missing
  tokens (→ recorded), presence of per-axis `--shadow-*` primitives (→ ignored, composed string
  wins), the full at-rule preamble (`@import`/`@custom-variant`/`@theme inline`/`@layer` → ignored),
  and the **`@custom-variant dark (…)` false-match guard** (must not be parsed as the `.dark` block).
  Font-stack extraction cases: `Outfit, sans-serif`→`Outfit`, `ui-serif, Georgia, …`→`Georgia`
  (generic skipped), `"Times New Roman", …`→`Times New Roman` (quotes stripped).
- **Emitter (G3):** `ThemeJson` schema snapshot; `emitDart(themeJson)` totality (every field
  consumed, S3); non-10 radius guard (S4).
- **End-to-end golden (G3):** **each** of the four `__fixtures__/claude.{hex,rgb,hsl,oklch}.css` →
  emit → assert the **full bundle** — 32 colors *and* radii *and* shadows *and* typography — equals
  `themes.dart`'s `_claudeLight`/`_claudeDark`/`_claudeRadii`/`_claudeShadows`/`_claudeType` (oklch
  colors within the ±1 tolerance, the other three byte-exact). Expected values are transcribed into
  a TS fixture that **mirrors** `themes.dart` (the human-checked source of those values; noted in
  the fixture header). Shadows are asserted directly: the §4.2 transform reproduces `_claudeShadows`
  byte-for-byte (a verified no-op, not a regeneration). `tracking` here is `0`, so a **separate
  emitter unit test** covers a non-zero `--tracking-normal` (e.g. `-0.025em` → `tracking: -0.025`)
  and its interpolation (G0's `FwTypographyTheme.lerp`); the golden alone wouldn't exercise non-zero
  tracking.

> **Input obtained:** the exact tweakcn export of theme `cmdght103000n04lh3e2ae93r` is committed
> verbatim in all four formats as `apps/docs/src/lib/generator/__fixtures__/claude.{hex,rgb,hsl,oklch}.css`.
> These are the real inputs behind `themes.dart`'s Claude theme and are the end-to-end goldens.

---

## 9. Risks & honest calls

- **OKLCH faithfulness proof** → resolved: the four-format fixtures give 32 authoritative
  `oklch → sRGB` pairs from tweakcn itself (in-gamut path), and a small set of Tailwind v4 source
  `oklch()` values covers the out-of-gamut clip path. No reliance on hand-produced artifacts.
- **oklch ≠ byte-exact to hex** → expected and bounded: tweakcn's oklch is an in-gamut projection,
  so it converges to ±1 of the hex export, not necessarily the same bit. Honest call (§12): we
  assert ±1 for oklch and byte-exact for hex/rgb/hsl, and pin the reviewed oklch ARGBs as a
  snapshot. A user pasting oklch gets the faithful-clip reproduction (= what tweakcn's hex shows).
- **`themes.dart` shadows as oracle** → checked against the real CSS: the canonical transform
  reproduces `_claudeShadows` exactly (§4.2), so the oracle is sound and the golden asserts shadows
  directly. No regeneration needed for this theme.
- **`tracking` is stored but not yet applied to rendered text** → recorded follow-on with mechanism
  (§4.3); the token still round-trips and interpolates, satisfying §7.
- **Perceptual gamut-map** is opt-in and lower-traffic → covered by clip≠map vectors, not a full
  golden; acceptable since faithful-clip is the default and the realistic shadcn range is in-gamut.

Nothing here is refused on cost grounds; every domain (color, radius, shadow, type) is emitted in
full per §7.
