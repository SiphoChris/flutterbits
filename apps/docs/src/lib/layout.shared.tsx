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
    links: [
      { text: 'flutterwindcss', url: '/docs/flutterwindcss' },
      { text: 'flutterbits', url: '/docs/flutterbits' },
      { text: 'Theme generator', url: '/theme-generator' },
    ],
    githubUrl: `https://github.com/${gitConfig.user}/${gitConfig.repo}`,
  };
}
