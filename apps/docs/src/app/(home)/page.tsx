import Link from 'next/link';
import Image from 'next/image';

/// The site landing. A soft, brand-tinted hero (the transparent logo over a faint
/// blue wash) over a short "two products" section that routes into each. Brand
/// colour comes from the retinted Fumadocs tokens + the `.brand-*` utilities in
/// global.css; the hero uses theme tokens so it reads in both light and dark.
export default function HomePage() {
  return (
    <main className="flex flex-1 flex-col">
      {/* Hero — a soft brand wash that blends into the site (light + dark). */}
      <section className="brand-hero text-fd-foreground">
        <div className="mx-auto max-w-5xl px-4 py-20 text-center sm:py-24">
          <div className="hero-logo-card mx-auto">
            <Image
              src="/flutterwindcss-image2-no-bg.png"
              alt="flutterbits"
              width={677}
              height={369}
              priority
              className="h-auto w-[min(360px,72vw)]"
            />
          </div>
          <h1 className="mt-10 text-4xl font-bold tracking-tight sm:text-5xl">
            Tailwind &amp; shadcn/ui, <span className="brand-gradient-text">for Flutter</span>
          </h1>
          <p className="mx-auto mt-4 max-w-2xl text-balance text-fd-muted-foreground">
            A Tailwind-style styling engine and a shadcn-style component registry — with the trick no
            other Flutter UI library has: paste any tweakcn/shadcn theme and get a working Flutter{' '}
            <code className="rounded bg-fd-primary/10 px-1.5 py-0.5 text-fd-foreground">
              theme.dart
            </code>
            .
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-3">
            <Link
              href="/docs/flutterwindcss"
              className="rounded-lg bg-fd-primary px-5 py-2.5 text-sm font-medium text-fd-primary-foreground transition-opacity hover:opacity-90"
            >
              Get started
            </Link>
            <Link
              href="/theme-generator"
              className="rounded-lg border border-fd-border px-5 py-2.5 text-sm font-medium text-fd-foreground transition-colors hover:bg-fd-muted"
            >
              Try the theme generator
            </Link>
          </div>
        </div>
      </section>

      {/* Two products. */}
      <section className="mx-auto w-full max-w-5xl px-4 py-16">
        <h2 className="text-center text-sm font-semibold uppercase tracking-wide text-fd-muted-foreground">
          Two layers, one workflow
        </h2>
        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          <Link
            href="/docs/flutterwindcss"
            className="group rounded-xl border border-fd-border bg-fd-card p-6 transition-colors hover:border-fd-primary"
          >
            <h3 className="text-lg font-semibold">
              flutter<span className="text-fd-primary">windcss</span>
            </h3>
            <p className="mt-1 text-sm text-fd-muted-foreground">
              The styling <strong>engine</strong> — Tailwind&apos;s design tokens and utility
              vocabulary (<code>.tw</code>) over Flutter&apos;s primitive widgets, themed through
              semantic tokens. Material-free.
            </p>
            <span className="mt-3 inline-block text-sm font-medium text-fd-primary group-hover:underline">
              Read the docs →
            </span>
          </Link>

          <Link
            href="/docs/flutterbits"
            className="group rounded-xl border border-fd-border bg-fd-card p-6 transition-colors hover:border-fd-primary"
          >
            <h3 className="text-lg font-semibold">
              flutter<span className="text-fd-primary">bits</span>
            </h3>
            <p className="mt-1 text-sm text-fd-muted-foreground">
              The component <strong>registry</strong> — shadcn/ui-style copy-paste components you
              own, styled entirely through flutterwindcss tokens.{' '}
              <span className="font-medium text-fd-foreground">Coming soon.</span>
            </p>
            <span className="mt-3 inline-block text-sm font-medium text-fd-primary group-hover:underline">
              Overview →
            </span>
          </Link>
        </div>

        <p className="mt-8 text-center text-sm text-fd-muted-foreground">
          Built in the spirit of{' '}
          <a className="underline hover:text-fd-primary" href="https://tailwindcss.com" target="_blank" rel="noreferrer">
            Tailwind CSS
          </a>
          ,{' '}
          <a className="underline hover:text-fd-primary" href="https://ui.shadcn.com" target="_blank" rel="noreferrer">
            shadcn/ui
          </a>{' '}
          and{' '}
          <a className="underline hover:text-fd-primary" href="https://tweakcn.com" target="_blank" rel="noreferrer">
            tweakcn
          </a>
          , on{' '}
          <a className="underline hover:text-fd-primary" href="https://flutter.dev" target="_blank" rel="noreferrer">
            Flutter
          </a>
          .
        </p>
      </section>
    </main>
  );
}
