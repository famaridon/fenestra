import { useCurrentFrame } from 'remotion';
import { fade, point, rect, SNAP } from '../anim';
import { Display, Stage, Window } from '../components/Desktop';
import { Cursor, SnapAssist } from '../components/Overlay';
import { SCREEN, zone } from '../geometry';
import { AFTER_POINTER } from './Mouse';
import { Clip, desk, type Scene, type SceneProps } from './shared';

const HOVER = 40;
const CLICK = 58;

// Center of the first item of the list, from the SnapAssist layout (3 items of 78px, 14px apart).
const free = zone(SCREEN, 'right');
const firstItem = { x: free.x + free.w / 2, y: free.y + (free.h - 262) / 2 + 39 };

const Assist = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const notes = rect(f, [
		[CLICK, desk.notes],
		[CLICK + 12, free, SNAP],
	]);
	const pointer = point(f, [
		[6, AFTER_POINTER],
		[HOVER, firstItem],
		[CLICK + 20, firstItem],
		[CLICK + 50, { x: free.x + 260, y: free.y + 120 }],
	]);
	const picked = f >= CLICK;
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				<Window rect={desk.terminal} app="terminal" title={s.windows.terminal} />
				{!picked && <Window rect={notes} app="notes" title={s.windows.notes} />}
				<Window rect={desk.mail} app="mail" title={s.windows.mail} />
				<Window rect={zone(SCREEN, 'left')} app="safari" title={s.windows.safari} focused={!picked} />
				<SnapAssist
					rect={free}
					opacity={fade(f, 4, CLICK, 6)}
					hovered={f >= HOVER ? 0 : null}
					items={[
						{ app: 'notes', title: s.windows.notes },
						{ app: 'terminal', title: s.windows.terminal },
						{ app: 'mail', title: s.windows.mail },
					]}
				/>
				{picked && <Window rect={notes} app="notes" title={s.windows.notes} focused />}
			</Clip>
			<Cursor at={pointer} pressed={f >= CLICK - 3 && f < CLICK + 3} />
		</Stage>
	);
};

export const assist: Scene = { id: 'assist', caption: 'assist', duration: CLICK + 60, Component: Assist };
