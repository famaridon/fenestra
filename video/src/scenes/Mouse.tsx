import { useCurrentFrame } from 'remotion';
import { dragged, fade, grab, point, rect, SNAP } from '../anim';
import { Display, Preview, Stage, Window } from '../components/Desktop';
import { Cursor } from '../components/Overlay';
import { SCREEN, zone } from '../geometry';
import { Clip, desk, type Scene, type SceneProps } from './shared';

const PRESS = 30;
const AT_EDGE = 75;
const RELEASE = 100;

const start = desk.safari;
const handle = grab(start, 0.3);
const edge = { x: SCREEN.x + 3, y: 470 };
export const AFTER_POINTER = { x: SCREEN.x + 520, y: 520 };

const Mouse = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const held = dragged(start, handle, edge);
	const safari = rect(f, [
		[PRESS, start],
		[AT_EDGE, held],
		[RELEASE, held],
		[RELEASE + 12, zone(SCREEN, 'left'), SNAP],
	]);
	const pointer = point(f, [
		[0, { x: 1250, y: 760 }],
		[PRESS - 6, handle],
		[AT_EDGE, edge],
		[RELEASE + 6, edge],
		[RELEASE + 40, AFTER_POINTER],
	]);
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				<Window rect={desk.terminal} app="terminal" title={s.windows.terminal} />
				<Window rect={desk.notes} app="notes" title={s.windows.notes} />
				<Window rect={desk.mail} app="mail" title={s.windows.mail} />
				<Preview rect={zone(SCREEN, 'left')} opacity={fade(f, AT_EDGE - 2, RELEASE, 4)} />
				<Window rect={safari} app="safari" title={s.windows.safari} focused />
			</Clip>
			<Cursor at={pointer} pressed={f >= PRESS && f < RELEASE} />
		</Stage>
	);
};

export const mouse: Scene = { id: 'mouse', caption: 'mouse', duration: RELEASE + 45, Component: Mouse };
