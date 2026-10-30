// Renders the intro video and its poster in every language into out/.
// Usage: pnpm render [lang...]   (default: every language)
import { execFileSync } from 'node:child_process';

const langs = process.argv.slice(2).length ? process.argv.slice(2) : ['en', 'fr'];
const remotion = (...args) => execFileSync('pnpm', ['exec', 'remotion', ...args], { stdio: 'inherit' });

for (const lang of langs) {
	remotion('render', 'src/index.ts', `intro-${lang}`, `out/fenestra-intro-${lang}.mp4`);
	remotion('still', 'src/index.ts', `poster-${lang}`, `out/fenestra-intro-${lang}.jpg`, '--image-format=jpeg');
}
