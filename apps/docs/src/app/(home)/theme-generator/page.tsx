'use client';

import { useMemo, useState } from 'react';
import type { ThemeJson } from '@/lib/generator/types';
import {
  argbToCss,
  radiusSamples,
  runGenerator,
  shadowSamples,
  swatches,
} from '@/lib/generator/preview';
import { SAMPLE_THEME } from './sample';

/// G4 — the tweakcn → Flutter theme generator route (spec §7). Paste a tweakcn
/// Tailwind-v4 export; the generator runs live (auto-detecting each color format,
/// always faithful-clip), rejects v3, hard-gates the 32 colors, reports any
/// defaulted/dropped tokens, previews swatches + radius + shadow samples (light &
/// dark), and presents the generated `theme.dart` to copy.
export default function ThemeGeneratorPage() {
  const [css, setCss] = useState('');
  const gen = useMemo(() => runGenerator(css), [css]);

  return (
    <main className="mx-auto w-full max-w-6xl px-4 py-10">
      <header className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">Flutter theme generator</h1>
        <p className="mt-2 max-w-2xl text-fd-muted-foreground">
          Paste a{' '}
          <a className="underline" href="https://tweakcn.com" target="_blank" rel="noreferrer">
            tweakcn
          </a>{' '}
          / shadcn theme (the full CSS export, Tailwind&nbsp;v4) and copy a ready-to-use{' '}
          <code className="font-mono">theme.dart</code> for{' '}
          <code className="font-mono">flutterwindcss</code> — colors, radius, shadows and fonts,
          with nothing dropped.
        </p>
      </header>

      <section className="grid gap-6 lg:grid-cols-2">
        <div className="flex flex-col gap-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <label htmlFor="css-input" className="text-sm font-medium">
              Theme CSS
            </label>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setCss(SAMPLE_THEME)}
                className="rounded-md border border-fd-border px-2.5 py-1 text-xs font-medium hover:bg-fd-accent"
              >
                Try an example
              </button>
              <button
                type="button"
                onClick={() => setCss('')}
                className="rounded-md border border-fd-border px-2.5 py-1 text-xs font-medium hover:bg-fd-accent"
              >
                Clear
              </button>
            </div>
          </div>
          <textarea
            id="css-input"
            value={css}
            onChange={(e) => setCss(e.target.value)}
            spellCheck={false}
            placeholder={':root {\n  --background: oklch(1 0 0);\n  ...\n}\n.dark { ... }'}
            className="h-[28rem] w-full resize-y rounded-lg border border-fd-border bg-fd-card p-3 font-mono text-xs leading-relaxed outline-none focus-visible:ring-2 focus-visible:ring-fd-ring"
          />
        </div>

        <div className="flex flex-col gap-4">
          {gen.status === 'empty' && (
            <Placeholder>
              Paste a theme on the left to preview it and copy your{' '}
              <code className="font-mono">theme.dart</code>.
            </Placeholder>
          )}

          {gen.status === 'error' && <ErrorBanner message={gen.message} />}

          {gen.status === 'ok' && (
            <Result themeJson={gen.result.themeJson} dartSource={gen.result.dartSource} />
          )}
        </div>
      </section>
    </main>
  );
}

function Placeholder({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-full min-h-48 items-center justify-center rounded-lg border border-dashed border-fd-border p-6 text-center text-sm text-fd-muted-foreground">
      <p className="max-w-xs">{children}</p>
    </div>
  );
}

function ErrorBanner({ message }: { message: string }) {
  return (
    <div
      role="alert"
      className="rounded-lg border border-red-500/40 bg-red-500/10 p-4 text-sm text-red-700 dark:text-red-300"
    >
      <p className="font-semibold">Could not generate a theme</p>
      <p className="mt-1 whitespace-pre-wrap">{message}</p>
    </div>
  );
}

function Result({ themeJson, dartSource }: { themeJson: ThemeJson; dartSource: string }) {
  const notes = [...themeJson.meta.notes];
  if (themeJson.meta.droppedVars.length > 0) {
    notes.push(`Dropped unknown CSS vars: ${themeJson.meta.droppedVars.join(', ')}.`);
  }
  return (
    <>
      {notes.length > 0 && (
        <div className="rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-xs text-amber-800 dark:text-amber-200">
          <p className="font-semibold">Defaulted / dropped tokens</p>
          <ul className="mt-1 list-disc space-y-0.5 pl-4">
            {notes.map((n) => (
              <li key={n}>{n}</li>
            ))}
          </ul>
        </div>
      )}

      <DartSource source={dartSource} />

      <PreviewPanel themeJson={themeJson} brightness="light" />
      <PreviewPanel themeJson={themeJson} brightness="dark" />
    </>
  );
}

function DartSource({ source }: { source: string }) {
  const [copied, setCopied] = useState(false);
  const onCopy = async () => {
    try {
      await navigator.clipboard.writeText(source);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Clipboard API unavailable (e.g. insecure context) — leave the source
      // visible so the user can select and copy it manually.
    }
  };
  return (
    <figure className="overflow-hidden rounded-lg border border-fd-border bg-fd-card">
      <figcaption className="flex items-center justify-between border-b border-fd-border px-3 py-2">
        <span className="font-mono text-xs text-fd-muted-foreground">theme.dart</span>
        <button
          type="button"
          onClick={onCopy}
          className="rounded-md bg-fd-primary px-3 py-1 text-xs font-medium text-fd-primary-foreground transition-opacity hover:opacity-90"
        >
          {copied ? 'Copied!' : 'Copy'}
        </button>
      </figcaption>
      <pre className="max-h-[28rem] overflow-auto p-3 text-xs leading-relaxed">
        <code className="font-mono">{source}</code>
      </pre>
    </figure>
  );
}

function PreviewPanel({
  themeJson,
  brightness,
}: {
  themeJson: ThemeJson;
  brightness: 'light' | 'dark';
}) {
  const colors = themeJson.colors[brightness];
  const cardCss = argbToCss(colors.card);
  const borderCss = argbToCss(colors.border);
  return (
    <div
      className="rounded-xl border border-fd-border p-4"
      style={{ background: argbToCss(colors.background), color: argbToCss(colors.foreground) }}
    >
      <p className="mb-3 text-xs font-semibold uppercase tracking-wide opacity-70">{brightness}</p>

      <div className="grid grid-cols-4 gap-2 sm:grid-cols-8">
        {swatches(colors).map((s) => (
          <div key={s.field} className="flex flex-col items-center gap-1">
            <span
              title={`${s.label} — ${s.css}`}
              className="h-9 w-full rounded-md"
              style={{ background: s.css, border: `1px solid ${borderCss}` }}
            />
            <span className="w-full truncate text-center text-[10px] leading-tight opacity-70">
              {s.label}
            </span>
          </div>
        ))}
      </div>

      <div className="mt-4 flex flex-wrap items-end gap-3">
        {radiusSamples(themeJson).map((r) => (
          <div key={r.name} className="flex flex-col items-center gap-1">
            <span
              className="h-12 w-12"
              style={{
                background: cardCss,
                border: `1px solid ${borderCss}`,
                borderRadius: `${r.px}px`,
              }}
            />
            <span className="text-[10px] opacity-70">
              {r.name} · {r.px}px
            </span>
          </div>
        ))}
      </div>

      <div className="mt-5 flex flex-wrap items-end gap-4">
        {shadowSamples(themeJson).map((sh) => (
          <div key={sh.name} className="flex flex-col items-center gap-1">
            <span
              className="h-12 w-12 rounded-lg"
              style={{ background: cardCss, boxShadow: sh.css }}
            />
            <span className="text-[10px] opacity-70">{sh.name}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
