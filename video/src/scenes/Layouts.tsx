import { useCurrentFrame } from 'remotion';
import { fade, point, rect, SNAP } from '../anim';
import { Display, Stage, Window } from '../components/Desktop';
import { Cursor, paletteZone, SnapLayouts } from '../components/Overlay';
import { floating, SCREEN, zone, type Zone } from '../geometry';
import { Clip, SceneCaption, type Scene, type SceneProps } from './shared';

const ON_BUTTON = 34;
const OPEN = 46;
const HOVER = 80;
const CLICK = 96;

// Layouts offered with the default zones, as in Fenestra.
const layouts: Zone[][] = [
	['left', 'right'],
	['left', 'topRight', 'bottomRight'],
	['topLeft', 'bottomLeft', 'right'],
	['topLeft', 'topRight', 'bottomLeft', 'bottomRight'],
	['full'],
];

const mail = floating(SCREEN, 0.3, 0.1, 0.46, 0.6);
// Green button of the title bar: third light, 13px wide, 8px apart, 14px from the edge.
const button = { x: mail.x + 14 + 2 * 21 + 6.5, y: mail.y + 17 };
const palette = { x: button.x - 6.5 - 16, y: mail.y + 34 + 8 };
const target = paletteZone(palette, 1, 'topRight');
const aim = { x: target.x + target.w / 2, y: target.y + target.h / 2 };

const Layouts = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const placed = rect(f, [
		[CLICK, mail],
		[CLICK + 12, zone(SCREEN, 'topRight'), SNAP],
	]);
	const pointer = point(f, [
		[0, { x: 1250, y: 760 }],
		[ON_BUTTON, button],
		[OPEN + 14, button],
		[HOVER, aim],
		[CLICK + 20, aim],
		[CLICK + 50, { x: 1150, y: 640 }],
	]);
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				<Window rect={floating(SCREEN, 0.04, 0.3, 0.4, 0.62)} app="terminal" title={s.windows.terminal} />
				<Window rect={placed} app="mail" title={s.windows.mail} focused />
				<SnapLayouts
					at={palette}
					layouts={layouts}
					hovered={f >= HOVER ? { index: 1, zone: 'topRight' } : null}
					opacity={fade(f, OPEN, CLICK, 6)}
				/>
			</Clip>
			<Cursor at={pointer} pressed={f >= CLICK - 3 && f < CLICK + 3} />
			<SceneCaption text={s.layouts} />
		</Stage>
	);
};

export const snapLayouts: Scene = { id: 'layouts', duration: CLICK + 60, Component: Layouts };
