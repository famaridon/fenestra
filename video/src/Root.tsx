import { Composition, Freeze, Series, Still } from 'remotion';
import { type Lang, strings } from './i18n';
import { assist } from './scenes/Assist';
import { border } from './scenes/Border';
import { displays } from './scenes/Displays';
import { keyboard } from './scenes/Keyboard';
import { mouse } from './scenes/Mouse';
import type { Scene } from './scenes/shared';
import { outro, title } from './scenes/Title';

// The video, in order. Add, remove or reorder scenes here.
const scenes: Scene[] = [title, mouse, assist, border, keyboard, displays, outro];

const FPS = 30;
const duration = scenes.reduce((sum, sc) => sum + sc.duration, 0);

const Intro = ({ lang }: { lang: Lang }) => (
	<Series>
		{scenes.map(({ id, duration, Component }) => (
			<Series.Sequence key={id} durationInFrames={duration} name={id}>
				<Component s={strings[lang]} />
			</Series.Sequence>
		))}
	</Series>
);

// Poster image: the Snap Assist list on screen.
const Poster = ({ lang }: { lang: Lang }) => (
	<Freeze frame={45}>
		<assist.Component s={strings[lang]} />
	</Freeze>
);

export const Root = () => (
	<>
		{(Object.keys(strings) as Lang[]).map((lang) => (
			<Composition
				key={lang}
				id={`intro-${lang}`}
				component={Intro}
				defaultProps={{ lang }}
				durationInFrames={duration}
				fps={FPS}
				width={1920}
				height={1080}
			/>
		))}
		{(Object.keys(strings) as Lang[]).map((lang) => (
			<Still
				key={lang}
				id={`poster-${lang}`}
				component={Poster}
				defaultProps={{ lang }}
				width={1920}
				height={1080}
			/>
		))}
	</>
);
