import Link from 'next/link';

/// The site landing. Frames the two products and routes into each — the styling
/// engine (flutterwindcss) and the component registry (flutterbits) — plus the
/// theme generator. Kept consistent with the Fumadocs neutral theme.
export default function HomePage() {
  return (
    <main className="mx-auto w-full max-w-5xl px-4 py-16">
      <div className="text-center">
        <h1 className="text-4xl font-bold tracking-tight">flutterbits</h1>
        <p className="mx-auto mt-3 max-w-2xl text-fd-muted-foreground">
          Tailwind CSS and shadcn/ui, brought to Flutter. A Tailwind-style styling engine and a
          copy-paste component registry — with the headline trick no other Flutter UI library has:
          paste any tweakcn/shadcn theme and get a working Flutter <code>theme.dart</code>.
        </p>
      </div>

      <div className="mt-12 grid gap-4 sm:grid-cols-2">
        <Link
          href="/docs/flutterwindcss"
          className="group rounded-xl border border-fd-border bg-fd-card p-6 transition-colors hover:bg-fd-accent"
        >
          <h2 className="text-lg font-semibold">flutterwindcss</h2>
          <p className="mt-1 text-sm text-fd-muted-foreground">
            The styling <strong>engine</strong> — Tailwind&apos;s design tokens and utility
            vocabulary (<code>.tw</code>) over Flutter&apos;s primitive widgets, themed through
            semantic tokens. Material-free.
          </p>
          <span className="mt-3 inline-block text-sm font-medium group-hover:underline">
            Read the docs →
          </span>
        </Link>

        <Link
          href="/docs/flutterbits"
          className="group rounded-xl border border-fd-border bg-fd-card p-6 transition-colors hover:bg-fd-accent"
        >
          <h2 className="text-lg font-semibold">flutterbits</h2>
          <p className="mt-1 text-sm text-fd-muted-foreground">
            The component <strong>registry</strong> — shadcn/ui-style copy-paste components you own,
            styled entirely through flutterwindcss tokens.{' '}
            <span className="font-medium">Coming soon.</span>
          </p>
          <span className="mt-3 inline-block text-sm font-medium group-hover:underline">
            Overview →
          </span>
        </Link>
      </div>

      <div className="mt-4">
        <Link
          href="/theme-generator"
          className="group flex items-center justify-between rounded-xl border border-fd-border p-6 transition-colors hover:bg-fd-accent"
        >
          <div>
            <h2 className="text-lg font-semibold">Theme generator</h2>
            <p className="mt-1 text-sm text-fd-muted-foreground">
              Paste a tweakcn/shadcn theme → copy a ready-to-use <code>theme.dart</code>.
            </p>
          </div>
          <span className="text-sm font-medium group-hover:underline">Open →</span>
        </Link>
      </div>
    </main>
  );
}
