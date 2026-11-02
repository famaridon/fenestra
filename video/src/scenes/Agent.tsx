import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { fade, rect, SNAP } from '../anim';
import { box, Display, Stage, Window } from '../components/Desktop';
import { floating, SCREEN, zone, type Rect } from '../geometry';
import { theme } from '../theme';
import { Clip, type Scene, type SceneProps } from './shared';

const PANEL_IN = 6;
const TYPE_FROM = 16;
const CHARS_PER_FRAME = 1.4;
const CALL_AFTER = 8;
const MOVE_AFTER = 14;
const STAGGER = 5;
const PANEL_OUT_AFTER = 40;

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;

// Untidy start, then every window placed by a single apply_layout call.
const windows = [
	{ app: 'safari', from: floating(SCREEN, 0.3, 0.04, 0.5, 0.58), to: zone(SCREEN, 'left') },
	{ app: 'terminal', from: floating(SCREEN, 0.04, 0.36, 0.38, 0.44), to: zone(SCREEN, 'topRight') },
	{ app: 'notes', from: floating(SCREEN, 0.56, 0.28, 0.4, 0.5), to: zone(SCREEN, 'bottomRight') },
] as const;

const PANEL: Rect = { x: SCREEN.x + (SCREEN.w - 860) / 2, y: SCREEN.y + SCREEN.h - 230, w: 860, h: 150 };

// Frames at which the prompt is fully typed, the tool is called and the windows move.
const timing = (prompt: string) => {
	const typed = TYPE_FROM + Math.ceil(prompt.length / CHARS_PER_FRAME);
	const call = typed + CALL_AFTER;
	const move = call + MOVE_AFTER;
	const done = move + STAGGER * (windows.length - 1) + 12;
	return { typed, call, move, done, out: done + PANEL_OUT_AFTER };
};

const Agent = ({ s }: SceneProps) => {
	const f = useCurrentFrame();
	const { fps } = useVideoConfig();
	const [prompt, call, placed] = s.agentPrompt;
	const t = timing(prompt);
	const shown = prompt.slice(0, Math.max(0, Math.floor((f - TYPE_FROM) * CHARS_PER_FRAME)));
	const caret = f < t.call && Math.floor(f / 8) % 2 === 0;
	const panelIn = spring({ frame: f - PANEL_IN, fps, config: { damping: 200 }, durationInFrames: 14 });
	const panelOpacity = Math.min(panelIn, interpolate(f, [t.out, t.out + 10], [1, 0], clamp));
	const chip = spring({ frame: f - t.call, fps, config: { damping: 14, stiffness: 180 } });
	const done = f >= t.done;
	return (
		<Stage>
			<Display screen={SCREEN} />
			<Clip screen={SCREEN}>
				{windows.map(({ app, from, to }, i) => (
					<Window
						key={app}
						app={app}
						title={s.windows[app]}
						focused={i === 0}
						rect={rect(f, [
							[t.move + i * STAGGER, from],
							[t.move + i * STAGGER + 14, to, SNAP],
						])}
					/>
				))}
			</Clip>
			<div
				style={{
					...box(PANEL),
					opacity: panelOpacity,
					transform: `translateY(${24 * (1 - panelIn)}px)`,
					borderRadius: 20,
					background: 'rgba(18,22,36,.86)',
					backdropFilter: 'blur(24px)',
					border: '1px solid rgba(255,255,255,.18)',
					boxShadow: '0 24px 60px rgba(0,0,0,.5)',
					padding: '26px 30px',
					display: 'flex',
					flexDirection: 'column',
					gap: 18,
					color: 'white',
				}}
			>
				<div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
					<div
						style={{
							width: 44,
							height: 44,
							borderRadius: 12,
							flexShrink: 0,
							background: `linear-gradient(135deg, ${theme.accent}, #a77bf3)`,
							display: 'flex',
							alignItems: 'center',
							justifyContent: 'center',
							fontSize: 26,
						}}
					>
						✦
					</div>
					<div style={{ fontSize: 26, fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden' }}>
						{shown}
						<span style={{ opacity: caret ? 1 : 0, color: '#9bb8ff' }}>▍</span>
					</div>
				</div>
				<div
					style={{
						alignSelf: 'flex-start',
						marginLeft: 62,
						opacity: f >= t.call ? chip : 0,
						transform: `scale(${0.85 + 0.15 * chip})`,
						transformOrigin: 'left center',
						display: 'flex',
						alignItems: 'center',
						gap: 12,
						padding: '8px 16px',
						borderRadius: 999,
						background: done ? 'rgba(52,211,153,.18)' : 'rgba(47,111,237,.25)',
						border: `1px solid ${done ? 'rgba(52,211,153,.6)' : 'rgba(155,184,255,.6)'}`,
						fontSize: 20,
						fontWeight: 600,
					}}
				>
					<span style={{ fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', color: done ? '#6ee7b7' : '#c7d6ff' }}>
						{done ? '✓' : '⋯'} {call}
					</span>
					{done && (
						<span style={{ color: 'rgba(255,255,255,.7)', fontWeight: 500, opacity: fade(f, t.done, Infinity, 6) }}>
							{placed}
						</span>
					)}
				</div>
			</div>
		</Stage>
	);
};

// Long enough for the longest prompt of every language.
export const agentDuration = (prompts: string[]) => Math.max(...prompts.map((p) => timing(p).out)) + 16;

export const agent = (prompts: string[]): Scene => ({
	id: 'agent',
	caption: 'agent',
	duration: agentDuration(prompts),
	Component: Agent,
});
