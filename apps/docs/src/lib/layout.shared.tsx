import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { gitConfig } from './shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      // The wordmark echoes the logo: "flutter" in the foreground, "bits" in the
      // brand blue (`text-fd-primary`, retinted in global.css).
      title: (
        <span className="font-semibold tracking-tight">
          flutter<span className="text-fd-primary">bits</span>
        </span>
      ),
    },
    // Top-navbar links. `on: 'nav'` keeps them in the navbar ONLY — not the
    // sidebar menu, where the product (flutterwindcss/flutterbits) tab switcher
    // already does the switching (that was the redundancy to remove).
    links: [
      { text: 'flutterwindcss', url: '/docs/flutterwindcss', on: 'nav' },
      { text: 'flutterbits', url: '/docs/flutterbits', on: 'nav' },
      { text: 'Theme generator', url: '/theme-generator', on: 'nav' },
    ],
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
  };
}
