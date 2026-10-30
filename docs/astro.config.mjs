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
			description: 'Le snap de Windows et Ubuntu, sur macOS.',
			defaultLocale: 'root',
			locales: {
				root: { label: 'Français', lang: 'fr' },
			},
			customCss: ['./src/styles/custom.css'],
			sidebar: [
				{
					label: 'Guide',
					items: [
						{ label: 'Installation', slug: 'guide/installation' },
						{ label: 'Snap à la souris', slug: 'guide/souris' },
						{ label: 'Raccourcis clavier', slug: 'guide/clavier' },
						{ label: 'Écran vertical', slug: 'guide/ecran-vertical' },
						{ label: 'Multi-écrans', slug: 'guide/multi-ecrans' },
						{ label: 'Bordure partagée', slug: 'guide/bordure-partagee' },
						{ label: 'Réglages', slug: 'guide/reglages' },
						{ label: 'Dépannage', slug: 'guide/depannage' },
					],
				},
				{
					label: 'Développement',
					items: [
						{ label: 'Architecture', slug: 'dev/architecture' },
						{ label: 'Expression de besoin', slug: 'dev/besoin' },
					],
				},
			],
		}),
	],
});
