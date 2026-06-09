# tweakcn → `theme.dart` generator — design

**Status:** approved design · **COMPLETE — G0–G5 all shipped (PR #22, #23, #25, #26, #27, #28)** · **Date:** 2026-06-08
(status updated 2026-06-09) · **Home:** `apps/docs` (Next.js / TypeScript) ·
**Audience:** engineers maintaining the generator. The whole pipeline — engine prereq (G0), color
core (G1), CSS parser (G2), emitter (G3), web UI (G4), and docs (G5) — is merged. The feature is done.

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
values only from the `:root` and `.dark` blocks** and ignore everything else (§2.2).

**Scope: Tailwind v4 export only (decided).** tweakcn can also export **Tailwind v3** CSS, which
differs structurally — colors are emitted as **bare `H S% L%` triples** (no `hsl()` wrapper) and
`:root`/`.dark` are **nested inside `@layer base { … }`** with `@tailwind` directives instead of
`@import`. v3 support is **deliberately descoped** (feasible — bare-HSL parse + nested-block match —
but not built; recorded, not "can't"). The generator MUST **detect** a v3 input (bare-number color
values / `@tailwind base`) and **reject it with a clear "Tailwind v3 export not supported — re-export
as Tailwind v4" error**, never silently misparse. URL input (paste a tweakcn share link, fetch the
CSS) is likewise a recorded possible enhancement, not v1.

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
the wild out-of-gamut design-token *source* values. Concretely — the Claude theme's dark
`destructive` `#ef4444` is exported as `oklch(0.6368 0.2078 25.3313)`, and that chroma `0.2078` is
exactly the value you get converting `#ef4444` *back* to oklch — so it round-trips byte-exact under
faithful-clip (verified Δ0 in G1). Contrast a genuinely out-of-gamut *source*: a vivid hand-authored
`oklch` (or a wide-gamut/P3 token) whose chroma exceeds the sRGB boundary is where clip vs gamut-map
diverge. Because every real tweakcn export is in-gamut, **all four formats converge** on the same
sRGB and gamut-map would only *move* already-correct colors — hence it is correctly opt-in. (Note:
do not equate `#ef4444` with Tailwind **v4** red-500 — that is `oklch(0.637 0.237 25.331)` →
`#fb2c36`; `#ef4444` is a distinct red. The in-gamut round-trip point holds regardless.)

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

**Parse robustness — fail loudly, never leak `NaN` (G1, hardened per §3.9).** `parseFloat`/`parseInt`
return `NaN` for non-numeric tokens, and `NaN` silently survives `clamp01`/`Math.round` to poison a
channel (yielding garbage hex like `"FFNANNANNAN"`). So every parser routes its components through a
shared `requireFinite(n, label, source)` choke-point that **throws** `Invalid <label> in color:
<value>` on a malformed token; `parseHex` additionally rejects non-hex digits before `parseInt`
(which would otherwise truncate `1g`→`1`); and `parseRgb` clamps numeric 0–255 channels into range
(`rgb(300 -5 0)` → `(255, 0, 0)`, not a 3-char garbage byte). Valid CSS — percentages, `none`,
scientific notation, slash/comma alpha, extra whitespace — still parses. This matters because G2 will
feed raw token strings straight into this layer.

> **Doc-comment convention:** the generator's TypeScript uses `///` line comments (not `/** */`
> JSDoc) **intentionally**, to match the Dart layer's house style across the repo. Tooling (tsc,
> ESLint, Vitest) is unaffected; if TypeDoc/JSDoc-lint is ever added, this is the one migration point.

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
  `theme.dart` won't compile. The generator never relies on that downstream; it **hard-gates the 32
  colors** before emit (S6). One exception: `--sidebar-ring` is **not** in tweakcn's Zod schema
  (only in its defaults), so a hand-edited theme may omit it — **default `sidebar-ring` to `ring`**
  (and report it) rather than gating on it. All other non-color tokens default gracefully (§7).
- **`radiusBase: <px>`** and **`radii: FwRadii(base:, sm:, md:, lg:, xl:)`** — explicit additive
  derivation from `--radius` (§4.1). **Never** `FwRadii.fromBase`.
- **`shadows: FwShadows(xs2:, xs:, sm:, md:, lg:, xl:, xl2:)`** — 7 slots from `--shadow-*` (§4.2).
- **`typography: FwTypographyTheme(sans:, serif:, mono:, tracking:)`** — family names + `tracking`
  (§4.3; the G0 engine change is shipped).

`theme.json` carries the same data in a fixed JSON schema (§4.4).

---

## 4. Per-domain emit rules

### 4.1 Radius — explicit additive

shadcn derives the set **additively** from `--radius`:
`sm = r − 4px`, `md = r − 2px`, `lg = r`, `xl = r + 4px` (px after rem→px at 16px root).

**Parse the `--radius` unit:** real presets use `rem`, `px`, and a bare `0`/`0px`/`0rem` (doom-64,
neo-brutalism use 0; violet-bloom 1.4rem; range seen `0 … 1.5rem`). Convert to logical px
(`rem × 16`, `px` as-is, bare `0` → 0). **Clamp the derived steps at ≥ 0:** at `r = 0`, additive
`sm`/`md` would be `−4`/`−2` (invalid radii) — clamp to `0` so a sharp-corner theme emits
`FwRadii(base: 0, sm: 0, md: 0, lg: 0, xl: 4)`.

Emit an **explicit** `FwRadii(base: r, sm: max(0,r−4), md: max(0,r−2), lg: r, xl: r+4)`. Do **not**
use `FwRadii.fromBase` — its `×0.6/0.8/1.0/1.4` factors coincide with the additive set *only* at the
10px default and diverge for any other base. `_claudeRadii` in `themes.dart` (base 16 → 12/14/16/20)
is the worked reference.

> **Regression guard (S4):** an emitter test at a **non-10** base — `--radius: 0.5rem` (8px) →
> `FwRadii(base: 8, sm: 4, md: 6, lg: 8, xl: 12)` — asserts the emitted Dart is exactly that and
> is **not** `fromBase(8)` (which would give sm 4.8 / md 6.4 / xl 11.2).

### 4.2 Shadows — 7 named slots, from the composed strings

Map the **seven named** composed slots **by name**: `--shadow-2xs`→`xs2`, `--shadow-xs`→`xs`,
`--shadow-sm`→`sm`, `--shadow-md`→`md`, `--shadow-lg`→`lg`, `--shadow-xl`→`xl`, `--shadow-2xl`→`xl2`.

> **Correction (corrected — generator, §12): the unprefixed `--shadow` does NOT map to `md`.** The
> original §7/spec said "`--shadow` (DEFAULT) maps onto `md`" — that is a wrong-value bug. tweakcn
> emits **eight** shadow levels: `2xs, xs, sm, `**`shadow`** (the Tailwind DEFAULT, between `sm` and
> `md`)`, md, lg, xl, 2xl`. Its `--shadow` is computed with the **`sm`** second-layer formula
> (`secondLayer("1px","2px")`), while `--shadow-md` uses `secondLayer("2px","4px")` — so
> `--shadow ≠ --shadow-md`. Feeding the DEFAULT into `md` emits the wrong `md`. `FwShadows` has a
> **7-slot** scale with **no DEFAULT level**, so the unprefixed `--shadow` is **dropped knowingly**
> (Flutter components reference the named slots, not a DEFAULT). This matches the verified oracle:
> the byte-for-byte `_claudeShadows` check below uses `--shadow-md` for `md`, not `--shadow`. (A
> future engine enhancement could add a DEFAULT slot to `FwShadows`; not needed now — recorded, not
> "can't.") AGENTS.md §7 carries the same error and is corrected in the same change.

**Authoritative source = the composed `--shadow-*` strings.** tweakcn also emits the per-axis
builder *inputs* (`--shadow-x/y/blur/spread/opacity/color`); these **bake into** the composed
strings and are **not** separate outputs. The parser reads the composed `--shadow-*` and **ignores**
the per-axis primitives (assert this in G2). **This is what makes colored/odd shadows universal for
free:** real presets use colored shadow bases (`hsl(255 86% 66%)`, `rgba(29,161,242,…)`, hex), hard
offsets (neo-brutalism `4px 4px`), `+4px` spread (claymorphism), opacity up to `1.0` — all already
baked into the composed strings, so we never reproduce tweakcn's builder formula. The composed
shadow **colors are always `hsl(H S% L% / a)`** (tweakcn hardcodes hsl for shadows regardless of the
theme's color format), so the shadow-color parser MUST accept `hsl(... / alpha)`.

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

### 4.3 Typography — families + `tracking` (G0 shipped — `FwTypographyTheme.tracking` exists)

Emit `FwTypographyTheme(sans:, serif:, mono:, tracking:)`:
- **Families — extract one name from a CSS font *stack*.** The values are stacks, not single names:
  `--font-sans: Outfit, sans-serif`, `--font-serif: ui-serif, Georgia, Cambria, "Times New Roman",
  Times, serif`, `--font-mono: Geist Mono, ui-monospace, monospace`. The faithful rule (matching
  `themes.dart`'s `sans:'Outfit'`, **`serif:'Georgia'`**, `mono:'Geist Mono'`) is: **take the first
  family that is not a CSS generic keyword, with surrounding quotes stripped.** Generic keywords to
  skip: `serif, sans-serif, monospace, cursive, fantasy, system-ui, math, emoji, fangsong, ui-serif,
  ui-sans-serif, ui-monospace, ui-rounded`. (That is why serif resolves to `Georgia`, skipping the
  leading `ui-serif`.) Strip **both** outer *and* inner quotes — real presets carry inner-quoted
  names like `'"Oxanium", sans-serif'`. If *every* entry is generic, keep the first. **Slots are not
  semantically typed:** tweakcn freely puts a serif/mono in the `sans` slot (e.g. the `mono` preset
  uses `Geist Mono` in all three; `starry-night` has `Merriweather, serif` as `sans`) — so extract
  and look up by family **name regardless of slot**, never assume `sans` slot ⇒ a sans-serif. The
  generator emits the chosen name **and** a clearly-commented `google_fonts` wiring stub. It MUST NOT
  pretend to bundle a font; an unknown/commercial family (e.g. `Signifier`) gets a
  `// TODO: bundle this font or map it` comment, never a silent fallback. Omitted `--font-*` →
  default to the platform family (report it, §7 graceful-default policy).
- **`tracking`:** from `--tracking-normal`, read from **`:root`** (tweakcn puts it only there, not in
  `.dark`) and applied to **both** light and dark typography. **Normalize the unit to em** (the
  `FwTypographyTheme.tracking` storage unit): `em` → as-is (`-0.025em` → `-0.025`); the CSS keyword
  **`normal`** → `0`; **`rem`** → same numeric (1rem≈1em); **`px`** → `px / 16` (em at 16px base,
  with an emitted comment that it was an absolute value and won't scale with font size — real
  presets like `notebook` use `0.5px`). `--tracking-normal` is **emitted only when ≠ `0em`**, so it
  is **absent** for most themes → default `0`. Conversion to Flutter's logical-px `letterSpacing`
  (em × font-size) happens at the text-apply site, **not** in the token.

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
  "meta": {
    "conversion": "faithful" | "perceptual",
    "droppedVars": [ /* recorded unknown --vars (parser) */ ],
    "notes": [ /* human-readable account of every defaulted/dropped token (§7.4) */ ]
  }
}
```

Colors (and shadow colors) serialize as `AARRGGBB` hex strings keyed by the **`FwColors` field name**
(camelCase: `card-foreground` → `cardForeground`). `meta.notes` (added — G3) is the
default-and-report channel (§7.4): every omitted font/shadow/radius (→ engine default), absolute-unit
tracking, dropped non-default `--spacing`, and `--sidebar-ring → ring` fallback lands here, and the
emitter renders them as `theme.dart` header comments so nothing is silent (§12).

`emit/` is strictly `RawTheme → ResolvedTheme → ThemeJson → dartSource` (the `color/` core resolves
each color; the non-color resolution — additive radius, the 7 shadow slots, font-stack extraction,
tracking — lives in `emit/resolve.ts`, since it is not color math). A test asserts `emitDart(themeJson)`
consumes **every** schema field (S3) — so "json is source of truth" is structural, not cosmetic.

---

## 5. G0 ✅ (merged — PR #22) — engine prereq: `tracking` on `FwTypographyTheme`

> **Status: shipped.** Everything below is done and merged; this section is the authoritative
> record of what was built and why.

A small, coordinated Dart change so the emit target exists. `FwTypographyTheme`
lives in `packages/flutterwindcss/lib/src/tokens/tokens.dart` (not `typography.dart`,
which holds only the static type scales); edit it there:

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

Ordered **G0 ✅ → G1 ✅ → G2 ✅ → G3 ✅ → G4 ✅ → G5 ✅** (all merged — the generator is complete).

| Module | Scope | Done when |
|---|---|---|
| **G0** ✅ | Engine: `tracking` field + `FwTypographyTheme.lerp` + `FwTokens.lerp` rewire + drift sweep | **Merged PR #22.** Dart analyze/format clean; existing goldens unchanged; new lerp unit test (tracking interpolates, families crossover) green |
| **G1** ✅ | `color/`: 4 format parsers (alpha + both L forms) + OKLCH→sRGB convert + faithful-clip + opt-in chroma-reduction gamut-map + `requireFinite` NaN-guards | **Merged PR #23.** 46 vitest tests; four-format convergence byte-exact (Δ0); malformed-input guards; lint + scoped tsc clean; covered by the `docs-generator` CI job |
| **G2** ✅ | `parse/`: tolerant brace-balanced `:root`/`.dark` tokenizer → `RawTheme`; records unknown vars (`RawTheme.unknownVars`); retains per-axis `--shadow-*` primitives + the DEFAULT `--shadow` verbatim (classified "known", ignored by emit); token **absence recorded by omission** from `RawBlock.vars` (for graceful-default reporting); **rejects Tailwind-v3 input** (`@tailwind` directive *or* bare `H S% L%` colors); `@custom-variant dark` false-match guard. Font-stack extraction is G3 (it reads `RawBlock.vars`), not G2. | **Merged PR #25.** 43 vitest tests across all 4 real fixtures (preamble ignored, false-match guard, messy whitespace/comments, alpha pass-through, per-axis retain, missing-token omission, unknown-var recording, v3-reject, missing-block errors); lint + scoped tsc clean |
| **G3** ✅ | `emit/`: `RawTheme → ResolvedTheme → ThemeJson → theme.dart` (`resolve.ts` + `theme-json.ts` + `dart.ts`); additive radius (clamped ≥0), 7 named shadow slots (paren-aware layer split so `rgba(…)`/`hsl(…)` colors survive; DEFAULT `--shadow` + per-axis primitives ignored), font-stack extraction, google_fonts stub, `tracking` (unit-normalized), `--spacing` drop-note, **non-color graceful defaults + `meta.notes` report** (per-slot shadow fallback, radius→10, fonts→platform, `--sidebar-ring`→`ring`). `_claudeShadows` matches the transform (verified — golden is byte-exact). | **Merged PR #26.** 67 vitest tests: 4-fixture end-to-end golden (32×2 colors converge to `themes.dart` — hex/rgb/hsl byte-exact, oklch ±1; radii/shadows/typography byte-exact), ThemeJson schema, `emitDart` totality (S3), non-10/zero radius (S4), tracking units, font cases, colored-shadow, DEFAULT≠md, missing-color gate, sidebar-ring default. Lint + scoped tsc clean. |
| **G4** ✅ | Route `src/app/(home)/theme-generator/page.tsx` (client) + nav link: paste → live `runGenerator` (auto-detect per value) → **reject v3** → **hard-gate 32 colors** + **default-and-report** (`meta.notes` + dropped vars banner) → preview (swatch grid + radius + shadow samples, light+dark, in the theme's own colors) → download `theme.dart` + `theme.json` + faithful/perceptual toggle. Real logic lives in the pure, tested `lib/generator/preview.ts`; `page.tsx` is a thin shell. | **Merged PR #27.** Dev-server verified (Playwright): renders the Claude theme (32×2 swatches = `themes.dart`, radius 12/14/16/20, 7 shadows), downloads `theme.dart`, v3 paste → error banner + downloads removed. 11 `preview.test.ts` tests (suite 167); route type-checked in CI (added to `tsconfig.generator.json`); lint clean. |
| **G5** ✅ | Docs MDX page (`content/docs/theme-generator.mdx`): usage, wiring `theme.dart` into `FwAnimatedTheme`, what-converts, faithful-vs-perceptual, and a Limitations section (v3-only, 32-color gate, fonts-not-bundled, `--spacing`/`tracking`/DEFAULT-`--shadow` caveats) + nav `meta.json`; full drift sweep of §7/README. | **Merged PR #28.** Renders on the dev server (Callouts/Cards/code block verified via Playwright); root README "shipped/next" + `apps/docs` layout note updated; no doc contradicts code. |

---

## 7. Web UI (G4 ✅ — shipped PR #27)

Single route at `src/app/(home)/theme-generator/page.tsx` (a `'use client'` component;
the pure logic lives in the tested `lib/generator/preview.ts` so the component stays a thin shell).
Behavior:
1. **Paste** the full tweakcn v4 CSS into a textarea.
2. **Reject Tailwind v3 input** up front (bare `H S% L%` colors / `@tailwind base`) with a clear
   "re-export as Tailwind v4" message (§1) — never misparse it.
3. **Auto-detect** each value's format per declaration (formats can mix within a theme).
4. **Hard-validate the 32 colors** per block (excluding `--sidebar-ring`, which defaults to `ring`).
   Missing any of the 32 → **block download**, show the exact list. Rationale (S6): `FwColors` has
   no defaults, so a partial `theme.dart` won't compile, and a web user has no compiler. **Non-color
   tokens default gracefully + are reported:** omitted `--font-*` → platform family; omitted
   shadow → engine default scale; absent `--tracking-normal` → 0; non-default/absent `--spacing`
   → dropped. The UI lists every token it **defaulted** so nothing is silent (§12). Real presets
   need this — e.g. *T3-Chat*, *Caffeine*, *Claude* define only colors + radius.
5. **Preview** (read-only, light + dark side-by-side): a swatch grid of the 32 colors, the four
   radius samples, and the 7 shadow samples. (No mock-component preview — an HTML approximation of
   Flutter rendering would mislead.)
6. **Conversion toggle:** faithful-clip (default) ↔ perceptual gamut-map.
7. **Download** `theme.dart` and `theme.json`.

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
    palette JSON alone is hex-only and would just test the hex parser — circular). **Tolerance
    (corrected — G1):** `hex`/`rgb`/`hsl` are asserted **byte-exact** (deterministic — no
    transcendental math), and `oklch` is asserted **within ±1 per channel** because libm
    `pow`/`cos`/`sin` may differ by ~1 ULP across platforms and could flip a rounding boundary; this
    is a deliberate, documented tolerance, not a silent relaxation. In practice the observed delta is
    **0** for all Claude tokens (verified in G1), so a regression of even 1 LSB is visible.
  - **Out-of-gamut clip-vs-map behavior:** asserted with a **synthetic, clearly out-of-gamut**
    `oklch` (e.g. `oklch(0.7 0.3 25)`): faithful **clips** (≥1 channel pinned to 0 or 1) while
    perceptual **reduces chroma** (hue-preserved), stays in gamut, and differs from faithful. (This
    replaces an earlier, incorrect spec example — `oklch(0.637 0.237 25.331)` is in fact *in-gamut*
    and maps to `#fb2c36`, not a clipped `#ef4444`. Faithfulness against real values is proven
    byte-exact by the four-format convergence, which covers the in-gamut path real exports use.)
  - Per-channel matrix vectors (math internal-consistency), alpha-syntax cases (`hsl(… / 0.10)`,
    `oklch(… / 0.1)`), and percent-vs-unit OKLCH lightness.
- **Parser (G2) ✅:** fixtures for messy whitespace/comments, all four formats, alpha syntax (kept
  verbatim), missing tokens (→ recorded by omission), presence of per-axis `--shadow-*` primitives
  (→ retained verbatim, classified "known"; the composed string is what emit reads), the full at-rule
  preamble (`@import`/`@custom-variant`/`@theme inline`/`@layer` → ignored via brace-balanced
  top-level extraction), and the **`@custom-variant dark (…)` false-match guard** (must not be parsed
  as the `.dark` block). **Font-stack *extraction* is an emit transform (G3)** — G2 captures the full
  verbatim stack (`--font-serif: ui-serif, Georgia, …`) because the parse stage is verbatim-only per
  the §2 architecture; the extraction cases below live with G3.
- **Universality (G2/G3) ✅ — the variety the research surfaced:** a **colored-shadow** fixture
  (`hsl(255 86% 66%)` / `rgba(...)` shadow base → correct `BoxShadow` color via the composed string);
  the **`--shadow` DEFAULT ≠ `--shadow-md`** guard (assert `md` reads `--shadow-md`, and the DEFAULT
  `--shadow` is dropped); **radius zero** (`--radius: 0px` → `FwRadii(0,0,0,0,4)`, clamped, not
  negative); **tracking units** (`normal`→0, `0.5px`→`0.03125` with comment, `0rem`→0); **missing
  non-color tokens** (a colors+radius-only theme → fonts/shadow/tracking default, all *reported*);
  **missing `--sidebar-ring`** → defaults to `ring`; and a **Tailwind-v3 input → rejected** with the
  clear error (not misparsed).
- **Emitter (G3) ✅:** `ThemeJson` schema snapshot; `emitDart(themeJson)` totality (every field
  consumed, S3); non-10 radius guard (S4). **Font-stack extraction cases** (read from the verbatim
  `RawBlock.vars` the parser produced): `Outfit, sans-serif`→`Outfit`, `ui-serif, Georgia, …`→
  `Georgia` (generic skipped), `"Times New Roman", …`→`Times New Roman` (outer quotes),
  `'"Oxanium", …'`→`Oxanium` (inner quotes), `Merriweather, serif` in the `sans` slot
  (cross-category, by name).
- **End-to-end golden (G3) ✅:** **each** of the four `__fixtures__/claude.{hex,rgb,hsl,oklch}.css` →
  emit → assert the **full bundle** — 32 colors *and* radii *and* shadows *and* typography — equals
  `themes.dart`'s `_claudeLight`/`_claudeDark`/`_claudeRadii`/`_claudeShadows`/`_claudeType` (oklch
  colors within the ±1 tolerance, the other three byte-exact; **observed delta 0**). Expected values
  are transcribed into `__fixtures__/claude-expected.ts`, which **mirrors** `themes.dart` (the
  human-checked source of those values; noted in the fixture header). Shadows are asserted directly: the §4.2 transform reproduces `_claudeShadows`
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
  `oklch → sRGB` pairs from tweakcn itself (in-gamut path; G1 reproduces them Δ0), and a synthetic
  clearly-out-of-gamut `oklch` exercises the clip-vs-map path behaviorally (§8). No reliance on
  hand-produced artifacts.
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

---

## 10. Universality evaluation (2026-06-09 — audited against the live tweakcn source)

A three-pass adversarial study of `jnsahaj/tweakcn` (its theme **schema**, all **42 preset
themes**, and its **CSS export code**) answered: *can we realistically build a universal generator
that converts ANY tweakcn theme?* **Verdict: yes** — the token model is complete and the variation
is bounded. Findings, and how this spec now covers them:

**De-risking confirmations**
- **No surprise token categories.** tweakcn's stored schema is exactly 32 colors + 3 font stacks +
  `letter-spacing` + `radius` + 6 shadow-builder inputs + optional `spacing`. No font-size,
  line-height, font-weight, border-width, z-index, or opacity tokens. Our §5 model is a superset.
- **All 42 presets define all 32 colors** → the colors-only hard-gate is safe against real themes.
- **Reading the *composed* `--shadow-*` strings makes colored/odd shadows free** (§4.2) — colored
  bases, hard offsets, `1.0` opacity, `+4px` spread all bake into the strings; we never reproduce
  tweakcn's builder formula.

**Gaps the study found, now specced (decisions: v4-only; colors-only gate + graceful defaults)**

| # | Gap | Where fixed |
|---|-----|-------------|
| 1 | Tailwind **v3** export (bare `H S% L%`, `:root`/`.dark` nested in `@layer base`) | **Descoped** — detect & reject with a clear message (§1, §7.2). Feasible, recorded, not built. |
| 2 | **`--shadow` DEFAULT ≠ `--shadow-md`** (mapping DEFAULT→md emitted a wrong `md`) | Correctness fix: map 7 named slots, drop DEFAULT (§4.2 + AGENTS.md §7). |
| 3 | Non-color tokens routinely **omitted** (fonts/shadow/tracking/spacing; e.g. T3-Chat/Caffeine/Claude) | Graceful default + report; gate colors only (§3, §7.4). |
| 4 | `letter-spacing` not always em: `normal`, `0.5px`, `0rem` | Unit-normalize to em (§4.3). |
| 5 | Radius `0`/negative-clamp; rem/px/bare-0 units | Parse units, clamp ≥0 (§4.1). |
| 6 | Font inner-quotes, cross-category slots, commercial fonts | Strip inner+outer quotes, look up by name regardless of slot (§4.3). |
| 7 | `--sidebar-ring` absent from tweakcn's Zod schema | Default to `ring` if missing (§3). |

None is a wall; each has a small concrete fix, all folded above. "Universal" (within the v4-only
decision) is a set of bounded parser hardenings, not a redesign.
