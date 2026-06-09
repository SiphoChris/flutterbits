import type { RawBlock, RawTheme } from '../types';
import { KNOWN_VAR_NAMES } from '../types';

/// G2 — the CSS parse stage. Turns a pasted tweakcn **Tailwind-v4** export into a
/// [RawTheme]: the `:root` (light) and `.dark` (dark) blocks as verbatim property
/// maps, plus any out-of-contract vars. Color/unit interpretation is downstream
/// (color/ + emit/); this stage only locates the two blocks and reads their
/// `--name: value` declarations, robust to the full at-rule preamble (spec §2.2).

/// A `--background` value that is a bare `H S% L%` triple (no `hsl()` wrapper) is
/// the structural tell of a **Tailwind-v3** export (spec §1). Allows an optional
/// leading sign and decimals; the second/third components carry a `%`.
const BARE_HSL_TRIPLE = /^-?[\d.]+\s+-?[\d.]+%\s+-?[\d.]+%$/;

/// A `@tailwind` directive (`@tailwind base;`) is v3; v4 uses `@import "tailwindcss"`.
const TAILWIND_V3_DIRECTIVE = /@tailwind\b/;

/// Sentinel colors used to sniff a v3 bare-triple body when no `@tailwind`
/// directive is present (a hand-trimmed export may omit the directive).
const V3_SNIFF_COLORS = ['background', 'foreground', 'primary'] as const;

/// One top-level CSS rule: its selector/at-rule prelude and its `{ … }` body.
interface TopLevelBlock {
  readonly prelude: string;
  readonly body: string;
}

/// Strip `/* … */` block comments. tweakcn exports carry none, but the parser is
/// required to tolerate hand-edited input (spec §8). Line comments (`//`) are not
/// valid CSS and never appear.
function stripComments(css: string): string {
  return css.replace(/\/\*[\s\S]*?\*\//g, '');
}

/// Split CSS into its **top-level** rule blocks, tracking brace depth so nested
/// `{ … }` (e.g. the `* { … }` / `body { … }` rules inside `@layer base`) are not
/// mistaken for top-level blocks. Brace-balanced extraction is what lets us ignore
/// everything except `:root`/`.dark` (spec §2.2).
///
/// Statements without a body — `@import "tailwindcss";`,
/// `@custom-variant dark (&:is(.dark *));` — have no braces, so they fold into the
/// *prelude* of the next braced block; [selectorOf] strips them back off.
function extractTopLevelBlocks(css: string): TopLevelBlock[] {
  const blocks: TopLevelBlock[] = [];
  let depth = 0;
  let preludeStart = 0;
  let braceIdx = -1;
  for (let i = 0; i < css.length; i++) {
    const c = css[i];
    if (c === '{') {
      if (depth === 0) braceIdx = i;
      depth++;
    } else if (c === '}') {
      if (depth === 0) {
        // Stray closing brace — resync rather than going negative.
        preludeStart = i + 1;
        continue;
      }
      depth--;
      if (depth === 0) {
        blocks.push({
          prelude: css.slice(preludeStart, braceIdx).trim(),
          body: css.slice(braceIdx + 1, i),
        });
        preludeStart = i + 1;
      }
    }
  }
  return blocks;
}

/// The effective selector of a prelude: the part after the last `;` (which drops
/// any absorbed `@import`/`@custom-variant` statements) and after the last `}`
/// (defensive, for resynced input).
function selectorOf(prelude: string): string {
  const cut = Math.max(prelude.lastIndexOf(';'), prelude.lastIndexOf('}'));
  return prelude.slice(cut + 1).trim();
}

/// Whether a prelude's selector list contains `target` (e.g. `:root`, `.dark`),
/// matched as a whole comma-separated selector segment — so `@custom-variant dark
/// (&:is(.dark *))` (folded into a prelude, but always before a `;`) and a bare
/// `.dark` substring inside a value can never match the `.dark` *rule*.
function selectorMatches(prelude: string, target: string): boolean {
  return selectorOf(prelude)
    .split(',')
    .map((s) => s.trim())
    .includes(target);
}

/// Read a block body's `--name: value;` declarations into a verbatim map (key sans
/// `--`). Non-custom-property lines and blank segments are skipped. A custom
/// property value never contains a literal `;` (it terminates the declaration), so
/// splitting on `;` is safe; only the first `:` separates name from value.
function parseDecls(body: string): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const decl of body.split(';')) {
    const trimmed = decl.trim();
    if (trimmed === '') continue;
    const colon = trimmed.indexOf(':');
    if (colon === -1) continue;
    const name = trimmed.slice(0, colon).trim();
    if (!name.startsWith('--')) continue;
    vars[name.slice(2)] = trimmed.slice(colon + 1).trim();
  }
  return vars;
}

/// The clear, user-facing message for a rejected Tailwind-v3 input (spec §1, §7.2).
function v3Error(): Error {
  return new Error(
    'Tailwind v3 export not supported — re-export this theme as Tailwind v4. ' +
      '(v3 emits bare `H S% L%` colors under `@layer base` with `@tailwind` directives; ' +
      'this generator reads the v4 `:root` / `.dark` blocks.)',
  );
}

/// Whether the parsed `:root` block carries bare `H S% L%` color triples — the
/// structural tell of a v3 export whose `@tailwind` directive was trimmed off.
function hasV3BareColors(root: RawBlock): boolean {
  return V3_SNIFF_COLORS.some((name) => {
    const v = root.vars[name];
    return v !== undefined && BARE_HSL_TRIPLE.test(v);
  });
}

/// Parse a pasted tweakcn Tailwind-v4 CSS export into a [RawTheme].
///
/// Reads values **only** from the `:root` and `.dark` rule blocks (spec §2.2);
/// `@import`, `@custom-variant`, `@theme inline`, `@layer base`, and any other
/// selector are ignored. Throws a clear error on a Tailwind-v3 input or when
/// either required block is missing.
export function parseTheme(css: string): RawTheme {
  // A `@tailwind` directive means a v3 export — and v3 nests `:root` inside
  // `@layer base`, so reject here, before block extraction would report a missing
  // top-level `:root` and mask the real cause.
  if (TAILWIND_V3_DIRECTIVE.test(css)) throw v3Error();

  const blocks = extractTopLevelBlocks(stripComments(css));

  const rootBlock = blocks.find((b) => selectorMatches(b.prelude, ':root'));
  if (rootBlock === undefined) {
    throw new Error(
      "Could not find a ':root { … }' block. Paste the full tweakcn Tailwind-v4 CSS export.",
    );
  }
  const darkBlock = blocks.find((b) => selectorMatches(b.prelude, '.dark'));
  if (darkBlock === undefined) {
    throw new Error(
      "Could not find a '.dark { … }' block. tweakcn exports light (`:root`) and dark (`.dark`) " +
        'together; paste the full Tailwind-v4 CSS export.',
    );
  }

  const root: RawBlock = { vars: parseDecls(rootBlock.body) };
  const dark: RawBlock = { vars: parseDecls(darkBlock.body) };

  // Secondary v3 tell: bare `H S% L%` colors even with the `@tailwind` directive
  // trimmed (e.g. a hand-pasted `:root`/`.dark` pair lifted out of `@layer base`).
  if (hasV3BareColors(root)) throw v3Error();

  const unknown = new Set<string>();
  for (const block of [root, dark]) {
    for (const name of Object.keys(block.vars)) {
      if (!KNOWN_VAR_NAMES.has(name)) unknown.add(name);
    }
  }

  return { root, dark, unknownVars: [...unknown].sort() };
}
