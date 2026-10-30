import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import type { Strings } from '../i18n';
import { captionWindow, scenes } from '../timeline';
import { theme } from '../theme';
import { Caption } from './Overlay';

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;

// Feature titles under the display. They stay in place while the scenes push each other,
// only the text changes: the old one rises and fades, the new one springs up from below.
export const Captions = ({ s }: { s: Strings }) => {
	const frame = useCurrentFrame();
	const { fps } = useVideoConfig();
	return (
		<>
			{scenes.map((scene, i) => {
				if (!scene.caption) return null;
				const [from, to] = captionWindow(i);
				if (frame < from || frame >= to) return null;
				const enter = spring({ frame: frame - from, fps, config: { damping: 200 }, durationInFrames: 14 });
				const leave = interpolate(frame, [to - 8, to], [0, 1], clamp);
				const [title, subtitle] = s[scene.caption];
				return (
					<div
						key={scene.id}
						style={{
							position: 'absolute',
							inset: 0,
							transform: `translateY(${30 * (1 - enter) - 24 * leave}px)`,
							filter: `blur(${6 * (1 - enter) + 6 * leave}px)`,
						}}
					>
						<Caption title={title} subtitle={subtitle} opacity={enter * (1 - leave)} />
					</div>
				);
			})}
		</>
	);
};

const SEGMENT = 120;
const SPACING = 10;

// One segment per feature, filling up while it plays.
export const Progress = () => {
	const frame = useCurrentFrame();
	const features = scenes.map((scene, i) => ({ scene, window: captionWindow(i) })).filter(({ scene }) => scene.caption);
	const first = features[0].window[0];
	const last = features[features.length - 1].window[1];
	const opacity = Math.min(interpolate(frame, [first, first + 10], [0, 1], clamp), interpolate(frame, [last - 10, last], [1, 0], clamp));
	if (opacity <= 0) return null;
	return (
		<div
			style={{
				position: 'absolute',
				left: 0,
				right: 0,
				top: 1048,
				display: 'flex',
				justifyContent: 'center',
				gap: SPACING,
				opacity,
			}}
		>
			{features.map(({ scene, window: [from, to] }) => (
				<div key={scene.id} style={{ width: SEGMENT, height: 5, borderRadius: 3, background: 'rgba(255,255,255,.16)', overflow: 'hidden' }}>
					<div style={{ width: `${100 * interpolate(frame, [from, to], [0, 1], clamp)}%`, height: '100%', background: theme.accent }} />
				</div>
			))}
		</div>
	);
};
