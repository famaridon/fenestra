import { TransitionSeries } from '@remotion/transitions';
import { Composition, Still } from 'remotion';
import { Captions, Progress } from './components/Captions';
import { Backdrop } from './components/Desktop';
import { Caption } from './components/Overlay';
import { type Lang, strings } from './i18n';
import { AgentPoster } from './scenes/Agent';
import { duration, FPS, scenes, transitions } from './timeline';

const Intro = ({ lang }: { lang: Lang }) => {
	const s = strings[lang];
	return (
		<Backdrop>
			<TransitionSeries>
				{scenes.flatMap(({ id, duration, Component }, i) => [
					<TransitionSeries.Sequence key={id} durationInFrames={duration} name={id}>
						<Component s={s} />
					</TransitionSeries.Sequence>,
					...(i < transitions.length
						? [<TransitionSeries.Transition key={`${id}-out`} timing={transitions[i].timing} presentation={transitions[i].presentation} />]
						: []),
				])}
			</TransitionSeries>
			<Captions s={s} />
			<Progress />
		</Backdrop>
	);
};

// Poster image: the AI agent has just placed every window.
const Poster = ({ lang }: { lang: Lang }) => (
	<Backdrop>
		<AgentPoster s={strings[lang]} />
		<Caption title={strings[lang].agent[0]} subtitle={strings[lang].agent[1]} />
	</Backdrop>
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
