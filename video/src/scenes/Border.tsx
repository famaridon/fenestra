import { useCurrentFrame } from 'remotion';
import { num, point } from '../anim';
import { Display, Stage, Window } from '../components/Desktop';
import { Cursor } from '../components/Overlay';
import { GAP, SCREEN, workArea, zone } from '../geometry';
import { Clip, SceneCaption, type Scene, type SceneProps } from './shared';

const PRESS = 28;
const RELEASE = 115;

const area = workArea(SCREEN);
const left = zone(SCREEN, 'left');
const middle = left.x + left.w + GAP / 2;
const y = area.y + area.h * 0.45;

const Border = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const border = num(f, [
		[PRESS, middle],
		[65, middle + 230],
		[78, middle + 230],
		[RELEASE, middle - 140],
	]);
	const pointer = point(f, [
		[0, { x: middle + 220, y: y + 100 }],
		[PRESS - 4, { x: middle, y }],
		[PRESS, { x: middle, y }],
		[65, { x: middle + 230, y }],
		[78, { x: middle + 230, y }],
		[RELEASE, { x: middle - 140, y }],
	]);
	const leftEdge = border - GAP / 2;
	const rightEdge = border + GAP / 2;
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				<Window rect={{ ...left, w: leftEdge - left.x }} app="safari" title={s.windows.safari} />
				<Window
					rect={{ ...left, x: rightEdge, w: area.x + area.w - rightEdge }}
					app="notes"
					title={s.windows.notes}
					focused
				/>
			</Clip>
			<Cursor at={pointer} resize={f >= PRESS - 4} />
			<SceneCaption text={s.border} />
		</Stage>
	);
};

export const border: Scene = { id: 'border', duration: RELEASE + 25, Component: Border };
