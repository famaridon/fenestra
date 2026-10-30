import { useCurrentFrame } from 'remotion';
import { rect, SNAP, type Stop } from '../anim';
import { Display, Stage, Window } from '../components/Desktop';
import { Keys } from '../components/Overlay';
import { floating, SCREEN, zone, type Rect } from '../geometry';
import { Clip, type Scene, type SceneProps } from './shared';

const restored = floating(SCREEN, 0.27, 0.14, 0.46, 0.56);

// Each shortcut, the frame it is pressed at, and where the window ends up.
const steps: { at: number; keys: string[]; to: Rect }[] = [
	{ at: 20, keys: ['⌃', '⌥', '←'], to: zone(SCREEN, 'left') },
	{ at: 60, keys: ['⌃', '⌥', '↑'], to: zone(SCREEN, 'topLeft') },
	{ at: 100, keys: ['⌃', '⌥', '↓'], to: zone(SCREEN, 'left') },
	{ at: 140, keys: ['⌃', '⌥', '↩'], to: zone(SCREEN, 'full') },
	{ at: 180, keys: ['⌃', '⌥', '⌫'], to: restored },
];

const stops: Stop<Rect>[] = steps.flatMap(({ at, to }, i): Stop<Rect>[] => [
	[at + 4, i === 0 ? restored : steps[i - 1].to],
	[at + 16, to, SNAP],
]);

const Keyboard = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				<Window rect={floating(SCREEN, 0.52, 0.3, 0.44, 0.6)} app="mail" title={s.windows.mail} />
				<Window rect={rect(f, stops)} app="terminal" title={s.windows.terminal} focused />
				{steps.map(({ at, keys }) => (
					<Keys key={at} keys={keys} from={at} to={at + 26} screen={SCREEN} />
				))}
			</Clip>
		</Stage>
	);
};

export const keyboard: Scene = { id: 'keyboard', caption: 'keyboard', duration: 225, Component: Keyboard };
