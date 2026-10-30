import { useCurrentFrame } from 'remotion';
import { rect, SNAP } from '../anim';
import { Display, Stage, Window } from '../components/Desktop';
import { Keys } from '../components/Overlay';
import { floating, zone, type Rect } from '../geometry';
import { SceneCaption, type Scene, type SceneProps } from './shared';

// A landscape display and a vertical one on its right.
const A: Rect = { x: 130, y: 205, w: 1060, h: 596 };
const B: Rect = { x: 1260, y: 80, w: 470, h: 836 };

const NEXT = 25;
const UP = 95;
const LEFT = 155;

// A window that is not snapped keeps its relative position on the next display.
const onA = floating(A, 0.4, 0.15, 0.5, 0.6);
const onB = floating(B, 0.4, 0.15, 0.5, 0.6);

const Displays = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const terminal = rect(f, [
		[NEXT + 4, onA],
		[NEXT + 20, onB, SNAP],
		[UP + 4, onB],
		[UP + 16, zone(B, 'top'), SNAP],
		// On a vertical display, ← / → cut the top half into quarters.
		[LEFT + 4, zone(B, 'top')],
		[LEFT + 16, zone(B, 'topLeft'), SNAP],
	]);
	return (
		<Stage>
			<Display screen={A} />
			<Display screen={B} />
			<Window rect={zone(A, 'left')} app="safari" title={s.windows.safari} />
			<Window rect={zone(B, 'bottom')} app="notes" title={s.windows.notes} />
			<Window rect={terminal} app="terminal" title={s.windows.terminal} focused />
			<Keys keys={['⌃', '⌥', '⌘', '→']} from={NEXT} to={NEXT + 30} screen={A} />
			<Keys keys={['⌃', '⌥', '↑']} from={UP} to={UP + 30} screen={B} />
			<Keys keys={['⌃', '⌥', '←']} from={LEFT} to={LEFT + 30} screen={B} />
			<SceneCaption text={s.displays} />
		</Stage>
	);
};

export const displays: Scene = { id: 'displays', duration: LEFT + 60, Component: Displays };
