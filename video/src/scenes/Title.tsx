import { Img, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { fade } from '../anim';
import { Stage } from '../components/Desktop';
import { theme } from '../theme';
import type { Scene, SceneProps } from './shared';

// Logo, name and a line under it: used to open and to close the video.
const Card = ({ heading, line, duration }: { heading: string; line: string; duration: number }) => {
	const f = useCurrentFrame();
	const { fps } = useVideoConfig();
	const pop = spring({ frame: f, fps, config: { damping: 13 } });
	const out = interpolate(f, [duration - 10, duration], [1, 0], { extrapolateLeft: 'clamp' });
	return (
		<Stage>
			<div
				style={{
					position: 'absolute',
					inset: 0,
					display: 'flex',
					flexDirection: 'column',
					alignItems: 'center',
					justifyContent: 'center',
					gap: 28,
					color: 'white',
					opacity: out,
				}}
			>
				<Img src={theme.logo} style={{ width: 200, height: 200, transform: `scale(${pop})` }} />
				<div style={{ fontSize: 96, fontWeight: 800, letterSpacing: -2, opacity: fade(f, 8, Infinity, 12) }}>{heading}</div>
				<div style={{ fontSize: 36, fontWeight: 500, color: '#b4c9fa', opacity: fade(f, 18, Infinity, 12) }}>{line}</div>
			</div>
		</Stage>
	);
};

const TITLE = 80;
const OUTRO = 100;

export const title: Scene = {
	id: 'title',
	duration: TITLE,
	Component: ({ s }: SceneProps) => <Card heading="Fenestra" line={s.tagline} duration={TITLE} />,
};

export const outro: Scene = {
	id: 'outro',
	duration: OUTRO,
	Component: ({ s }: SceneProps) => <Card heading={s.outro[0]} line={s.outro[1]} duration={OUTRO + 30} />,
};
