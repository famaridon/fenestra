import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import type { Point } from '../anim';
import type { Rect } from '../geometry';
import { theme } from '../theme';
import { AppIcon, type AppKind, box } from './Desktop';

export const Cursor = ({ at, pressed = false, resize = false }: { at: Point; pressed?: boolean; resize?: boolean }) =>
	resize ? (
		<svg
			width={40}
			height={24}
			viewBox="0 0 40 24"
			style={{ position: 'absolute', left: at.x - 20, top: at.y - 12, filter: 'drop-shadow(0 2px 3px rgba(0,0,0,.45))' }}
		>
			<path d="M2 12l9-8v5h18V4l9 8-9 8v-5H11v5z" fill="black" stroke="white" strokeWidth={1.6} strokeLinejoin="round" />
		</svg>
	) : (
	<svg
		width={34}
		height={34}
		viewBox="0 0 24 24"
		style={{
			position: 'absolute',
			left: at.x - 6,
			top: at.y - 3,
			transform: `scale(${pressed ? 0.88 : 1})`,
			transformOrigin: '6px 3px',
			filter: 'drop-shadow(0 2px 3px rgba(0,0,0,.45))',
		}}
	>
		<path d="M5 2.5v17.2l4.3-4.1 2.7 6.2 3-1.3-2.7-6.1H18L5 2.5z" fill="black" stroke="white" strokeWidth={1.4} strokeLinejoin="round" />
	</svg>
	);

// Key combination shown at the bottom of the display while a shortcut is pressed.
export const Keys = ({ keys, from, to, screen }: { keys: string[]; from: number; to: number; screen: Rect }) => {
	const frame = useCurrentFrame();
	const { fps } = useVideoConfig();
	if (frame < from || frame > to + 8) return null;
	const pop = spring({ frame: frame - from, fps, config: { damping: 14, stiffness: 180 } });
	const out = interpolate(frame, [to, to + 8], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
	return (
		<div
			style={{
				position: 'absolute',
				left: screen.x,
				width: screen.w,
				top: screen.y + screen.h - 150,
				display: 'flex',
				justifyContent: 'center',
				gap: 12,
				opacity: out,
				transform: `scale(${0.8 + 0.2 * pop})`,
			}}
		>
			{keys.map((k, i) => (
				<div
					key={i}
					style={{
						minWidth: 74,
						height: 74,
						padding: '0 18px',
						borderRadius: 14,
						background: 'rgba(20,24,36,.82)',
						border: '1px solid rgba(255,255,255,.25)',
						boxShadow: '0 6px 0 rgba(0,0,0,.35), 0 12px 30px rgba(0,0,0,.4)',
						color: 'white',
						fontSize: 36,
						fontWeight: 600,
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'center',
						fontFamily: '-apple-system, "SF Pro Display", sans-serif',
					}}
				>
					{k}
				</div>
			))}
		</div>
	);
};

// Scene title under the display.
export const Caption = ({ title, subtitle, opacity = 1 }: { title: string; subtitle: string; opacity?: number }) => (
	<div
		style={{
			position: 'absolute',
			left: 0,
			right: 0,
			top: 935,
			textAlign: 'center',
			color: 'white',
			opacity,
		}}
	>
		<div style={{ fontSize: 44, fontWeight: 800, letterSpacing: -0.5 }}>{title}</div>
		<div style={{ fontSize: 26, fontWeight: 500, color: '#b4c9fa', marginTop: 6 }}>{subtitle}</div>
	</div>
);

export type AssistItem = { app: AppKind; title: string };

// Snap Assist list shown in the free space.
export const SnapAssist = ({
	rect,
	items,
	hovered,
	opacity,
}: {
	rect: Rect;
	items: AssistItem[];
	hovered: number | null;
	opacity: number;
}) => (
	<div
		style={{
			...box(rect),
			opacity,
			borderRadius: 12,
			background: 'rgba(15,20,35,.55)',
			backdropFilter: 'blur(24px)',
			border: '1px solid rgba(255,255,255,.2)',
			display: 'flex',
			flexDirection: 'column',
			justifyContent: 'center',
			gap: 14,
			padding: 40,
		}}
	>
		{items.map((it, i) => (
			<div
				key={it.title}
				style={{
					display: 'flex',
					alignItems: 'center',
					gap: 18,
					padding: '16px 20px',
					borderRadius: 12,
					background: hovered === i ? theme.accent : 'rgba(255,255,255,.1)',
					border: `1px solid ${hovered === i ? '#9bb8ff' : 'rgba(255,255,255,.12)'}`,
					color: 'white',
					fontSize: 22,
					fontWeight: 600,
				}}
			>
				<AppIcon app={it.app} size={44} />
				{it.title}
			</div>
		))}
	</div>
);
