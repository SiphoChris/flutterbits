/// Generator-wide types and the CSS token-name contract.
///
/// This file is the shared vocabulary between the staged pipeline
/// (`parse → color → emit`, spec §2). G2 (`parse/`) produces a [RawTheme] of
/// verbatim CSS custom properties and uses [KNOWN_VAR_NAMES] to classify which
/// `--vars` are "unknown"; G3 (`emit/`) consumes the same name lists to map each
/// CSS property onto its `FwTokens` field and to gate the 32 colors.
///
/// Doc comments use `///` (not JSDoc) intentionally, to match the Dart layer's
/// house style across the repo (spec §2.1).

// === RawTheme — the G2 (parse) stage output ===

/// A single CSS rule block's custom properties, captured verbatim.
export interface RawBlock {
  /// Every `--name: value` declaration in the block. The key is the property
  /// name **without** the leading `--`; the value is the verbatim, trimmed
  /// declaration value (only `/* … */` comments are stripped — the value is
  /// otherwise unmodified, so the color/emit stages parse it).
  ///
  /// Nothing is dropped here (spec §2.2 "record, don't drop"): per-axis
  /// `--shadow-*` builder primitives, the unprefixed `--shadow` DEFAULT, and any
  /// unknown vars are all retained alongside the values we map. **Token absence
  /// is recorded by omission** — a contract token missing from a block simply has
  /// no key here, which is how G3/G4 detect a token to default-and-report.
  readonly vars: Readonly<Record<string, string>>;
}

/// The output of G2: the `:root` (light) and `.dark` blocks of a tweakcn
/// Tailwind-v4 export, each as a verbatim property map, plus the names of any
/// properties not in the known token contract.
export interface RawTheme {
  /// The `:root { … }` block — the light theme.
  readonly root: RawBlock;
  /// The `.dark { … }` block — the dark theme.
  readonly dark: RawBlock;
  /// CSS var names (sans `--`) found in `:root` or `.dark` that are **not** part
  /// of the known token contract ([KNOWN_VAR_NAMES]). Recorded here, never
  /// silently discarded (spec §2.2); de-duplicated across both blocks and sorted.
  /// G3 surfaces these as `meta.droppedVars` in `theme.json`.
  readonly unknownVars: readonly string[];
}

// === Token-name contract — the CSS custom-property names we understand ===

/// The 32 semantic color CSS custom-property names (sans `--`), in the canonical
/// order of the §5 token contract: 19 core + `chart-1…5` + 8 `sidebar*`. G3 maps
/// each to its `FwColors` field (e.g. `card-foreground` → `cardForeground`).
export const COLOR_VAR_NAMES = [
  'background',
  'foreground',
  'card',
  'card-foreground',
  'popover',
  'popover-foreground',
  'primary',
  'primary-foreground',
  'secondary',
  'secondary-foreground',
  'muted',
  'muted-foreground',
  'accent',
  'accent-foreground',
  'destructive',
  'destructive-foreground',
  'border',
  'input',
  'ring',
  'chart-1',
  'chart-2',
  'chart-3',
  'chart-4',
  'chart-5',
  'sidebar',
  'sidebar-foreground',
  'sidebar-primary',
  'sidebar-primary-foreground',
  'sidebar-accent',
  'sidebar-accent-foreground',
  'sidebar-border',
  'sidebar-ring',
] as const;

/// The seven **named** composed shadow slots (sans `--`), mapped by G3 to the
/// `FwShadows` 7-slot scale (`--shadow-2xs` → `xs2`, …, `--shadow-2xl` → `xl2`).
export const NAMED_SHADOW_VAR_NAMES = [
  'shadow-2xs',
  'shadow-xs',
  'shadow-sm',
  'shadow-md',
  'shadow-lg',
  'shadow-xl',
  'shadow-2xl',
] as const;

/// The unprefixed Tailwind DEFAULT shadow. It is **known but knowingly dropped**:
/// `FwShadows` has no DEFAULT slot, and tweakcn computes `--shadow` with the `sm`
/// second-layer formula so it is *not* `--shadow-md` (spec §4.2). Listed here so
/// it is classified "known" (not flagged as an unknown var) while still recorded
/// verbatim in [RawBlock.vars].
export const DEFAULT_SHADOW_VAR_NAME = 'shadow';

/// tweakcn's per-axis shadow **builder inputs**. They bake into the composed
/// `--shadow-*` strings and are NOT separate outputs — known, but deliberately
/// ignored by emit (spec §4.2). Listed so they are classified "known" while still
/// retained verbatim in [RawBlock.vars] (record-don't-drop).
export const IGNORED_SHADOW_VAR_NAMES = [
  'shadow-x',
  'shadow-y',
  'shadow-blur',
  'shadow-spread',
  'shadow-opacity',
  'shadow-color',
] as const;

/// Non-color, non-shadow scalar tokens read by emit: the radius base, the three
/// font stacks, the base letter-spacing, and the base spacing unit.
export const OTHER_VAR_NAMES = [
  'radius',
  'font-sans',
  'font-serif',
  'font-mono',
  'tracking-normal',
  'spacing',
] as const;

/// The full set of CSS var names the generator understands. Any `--var` in
/// `:root`/`.dark` outside this set is an "unknown var" ([RawTheme.unknownVars]).
export const KNOWN_VAR_NAMES: ReadonlySet<string> = new Set<string>([
  ...COLOR_VAR_NAMES,
  ...NAMED_SHADOW_VAR_NAMES,
  DEFAULT_SHADOW_VAR_NAME,
  ...IGNORED_SHADOW_VAR_NAMES,
  ...OTHER_VAR_NAMES,
]);
