import { loadFont } from '@remotion/google-fonts/Inter';
import { staticFile } from 'remotion';

const { fontFamily } = loadFont('normal', { weights: ['400', '500', '600', '700', '800'], subsets: ['latin', 'latin-ext'] });

// Same accent as the documentation site.
export const theme = {
	font: `${fontFamily}, -apple-system, sans-serif`,
	accent: '#2f6fed',
	accentSoft: '#dbe6fd',
	stage: 'radial-gradient(circle at 50% 30%, #1b2a4a 0%, #0b1020 70%)',
	wallpaper: 'linear-gradient(135deg, #3b7bf5 0%, #6a4fd8 55%, #c0569b 100%)',
	logo: staticFile('logo.svg'),
};
