import { spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { fade, rect, SNAP, type Stop } from '../anim';
import { box, Display, Stage, Window, type AppKind } from '../components/Desktop';
import { Keys } from '../components/Overlay';
import { floating, SCREEN, zone, type Rect } from '../geometry';
import { theme } from '../theme';
import { Clip, type Scene, type SceneProps } from './shared';

const STAGGER = 4;
const MOVE = 14;

type Layout = Record<AppKind, Rect>;

// Untidy start, then two workspaces recalled with their shortcut: every window moves in one go.
const start: Layout = {
	safari: floating(SCREEN, 0.3, 0.04, 0.5, 0.58),
	terminal: floating(SCREEN, 0.04, 0.36, 0.38, 0.44),
	notes: floating(SCREEN, 0.56, 0.28, 0.4, 0.5),
	mail: floating(SCREEN, 0.2, 0.2, 0.42, 0.5),
};

const workspaces: { at: number; keys: string[]; layout: Layout }[] = [
	{
		at: 24,
		keys: ['⌃', '⌥', '1'],
		layout: {
			safari: zone(SCREEN, 'left'),
			terminal: zone(SCREEN, 'topRight'),
			notes: zone(SCREEN, 'bottomRight'),
			mail: floating(SCREEN, 0.3, 0.3, 0.4, 0.4),
		},
	},
	{
		at: 110,
		keys: ['⌃', '⌥', '2'],
		layout: {
			mail: zone(SCREEN, 'left'),
			notes: zone(SCREEN, 'right'),
			safari: floating(SCREEN, 0.3, 0.3, 0.4, 0.4),
			terminal: floating(SCREEN, 0.05, 0.5, 0.4, 0.45),
		},
	},
];

const apps: AppKind[] = ['mail', 'safari', 'terminal', 'notes'];

// Where each window is over time: it moves `MOVE` frames after the shortcut, staggered per window.
const stops = (app: AppKind): Stop<Rect>[] =>
	workspaces.flatMap(({ at, layout }, i): Stop<Rect>[] => {
		const from = i === 0 ? start[app] : workspaces[i - 1].layout[app];
		const begin = at + 10 + apps.indexOf(app) * STAGGER;
		return [
			[begin, from],
			[begin + MOVE, layout[app], SNAP],
		];
	});

const CHIP: Rect = { x: SCREEN.x + SCREEN.w / 2 - 170, y: SCREEN.y + 70, w: 340, h: 58 };

// The name of the workspace being applied, shown with its shortcut.
const Chip = ({ label, from, to }: { label: string; from: number; to: number }) => {
	const f = useCurrentFrame();
	const { fps } = useVideoConfig();
	if (f < from || f > to + 10) return null;
	const pop = spring({ frame: f - from, fps, config: { damping: 16, stiffness: 160 } });
	return (
		<div
			style={{
				...box(CHIP),
				opacity: Math.min(pop, fade(f, from, to, 10)),
				transform: `translateY(${16 * (1 - pop)}px)`,
				borderRadius: 999,
				background: 'rgba(18,22,36,.86)',
				backdropFilter: 'blur(24px)',
				border: '1px solid rgba(255,255,255,.18)',
				boxShadow: '0 16px 40px rgba(0,0,0,.4)',
				display: 'flex',
				alignItems: 'center',
				justifyContent: 'center',
				gap: 12,
				color: 'white',
				fontSize: 24,
				fontWeight: 600,
			}}
		>
			<span style={{ color: theme.accent }}>▣</span>
			{label}
		</div>
	);
};

const Workspaces = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				{apps.map((app) => (
					<Window key={app} rect={rect(f, stops(app))} app={app} title={s.windows[app]} focused={app === 'safari'} />
				))}
				{workspaces.map(({ at, keys }) => (
					<Keys key={at} keys={keys} from={at} to={at + 26} screen={SCREEN} />
				))}
			</Clip>
			{workspaces.map(({ at }, i) => (
				<Chip key={at} label={s.workspaceNames[i]} from={at + 8} to={at + 70} />
			))}
		</Stage>
	);
};

export const workspacesScene: Scene = { id: 'workspaces', caption: 'workspaces', duration: 200, Component: Workspaces };
