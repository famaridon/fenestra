import type { TransitionPresentation, TransitionPresentationComponentProps } from '@remotion/transitions';
import { AbsoluteFill } from 'remotion';

type NoProps = Record<string, never>;

// Between two features: the next desktop pushes the previous one away, dipping back a little
// on the way, like a carousel.
const Push = ({ children, presentationDirection, presentationProgress: p }: TransitionPresentationComponentProps<NoProps>) => {
	const entering = presentationDirection === 'entering';
	const x = entering ? (1 - p) * 100 : -p * 100;
	const depth = Math.sin(Math.PI * p);
	return (
		<AbsoluteFill
			style={{
				transform: `translateX(${x}%) scale(${1 - 0.1 * depth})`,
				filter: depth > 0.01 ? `blur(${4 * depth}px)` : undefined,
				opacity: 1 - 0.3 * depth,
			}}
		>
			{children}
		</AbsoluteFill>
	);
};

// Opening and closing cards: the previous view grows and fades out, the next one settles in.
const ZoomFade = ({ children, presentationDirection, presentationProgress: p }: TransitionPresentationComponentProps<NoProps>) => {
	const entering = presentationDirection === 'entering';
	return (
		<AbsoluteFill
			style={{
				// The leaving view is gone by mid-transition, so its text never shows through the next one.
				opacity: entering ? p : Math.max(0, 1 - 2 * p),
				transform: `scale(${entering ? 0.92 + 0.08 * p : 1 + 0.12 * p})`,
			}}
		>
			{children}
		</AbsoluteFill>
	);
};

export const push = (): TransitionPresentation<NoProps> => ({ component: Push, props: {} });
export const zoomFade = (): TransitionPresentation<NoProps> => ({ component: ZoomFade, props: {} });
