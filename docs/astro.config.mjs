// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
	site: 'https://famaridon.github.io',
	base: '/fenestra',
	integrations: [
		starlight({
			title: 'Fenestra',
			logo: { src: './src/assets/logo.svg' },
			description: 'Windows and Ubuntu-style window snapping for macOS.',
			defaultLocale: 'root',
			locales: {
				root: { label: 'English', lang: 'en' },
				fr: { label: 'Français', lang: 'fr' },
			},
			customCss: ['./src/styles/custom.css'],
			sidebar: [
				{
					label: 'Guide',
					items: [
						{ slug: 'guide/installation' },
						{ slug: 'guide/mouse' },
						{ slug: 'guide/keyboard' },
						{ slug: 'guide/vertical-display' },
						{ slug: 'guide/multiple-displays' },
						{ slug: 'guide/shared-border' },
						{ slug: 'guide/snap-layouts' },
						{ slug: 'guide/snap-assist' },
						{ slug: 'guide/settings' },
						{ slug: 'guide/troubleshooting' },
					],
				},
				{
					label: 'Development',
					translations: { fr: 'Développement' },
					items: [{ slug: 'dev/architecture' }, { slug: 'dev/requirements' }],
				},
			],
		}),
	],
});
