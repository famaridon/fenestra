import type { ReactNode } from 'react';
import { useCurrentFrame } from 'remotion';
import { fade } from '../anim';
import { Caption } from '../components/Overlay';
import { floating, SCREEN, type Rect } from '../geometry';
import type { Strings } from '../i18n';

export type SceneProps = { s: Strings };

export type Scene = { id: string; duration: number; Component: (p: SceneProps) => ReactNode };

// Windows drawn in stage coordinates but clipped to their display.
export const Clip = ({ screen, children }: { screen: Rect; children: ReactNode }) => (
	<div
		style={{
			position: 'absolute',
			left: screen.x,
			top: screen.y,
			width: screen.w,
			height: screen.h,
			overflow: 'hidden',
			borderRadius: 14,
		}}
	>
		<div style={{ position: 'absolute', left: -screen.x, top: -screen.y, width: 1920, height: 1080 }}>{children}</div>
	</div>
);

export const SceneCaption = ({ text }: { text: [string, string] }) => {
	const frame = useCurrentFrame();
	return <Caption title={text[0]} subtitle={text[1]} opacity={fade(frame, 0, Infinity, 10)} />;
};

// Starting layout shared by the mouse, Snap Assist and shared border scenes.
export const desk = {
	safari: floating(SCREEN, 0.2, 0.12, 0.5, 0.64),
	notes: floating(SCREEN, 0.55, 0.06, 0.4, 0.56),
	terminal: floating(SCREEN, 0.04, 0.48, 0.36, 0.46),
	mail: floating(SCREEN, 0.5, 0.42, 0.42, 0.52),
};
