import { springTiming, type TransitionPresentation, type TransitionTiming } from '@remotion/transitions';
import { assist } from './scenes/Assist';
import { border } from './scenes/Border';
import { displays } from './scenes/Displays';
import { keyboard } from './scenes/Keyboard';
import { snapLayouts } from './scenes/Layouts';
import { mouse } from './scenes/Mouse';
import type { Scene } from './scenes/shared';
import { outro, title } from './scenes/Title';
import { push, zoomFade } from './transitions';

// The video, in order. Add, remove or reorder scenes here.
export const scenes: Scene[] = [title, mouse, assist, border, keyboard, displays, snapLayouts, outro];

export const FPS = 30;

type Transition = { duration: number; timing: TransitionTiming; presentation: TransitionPresentation<Record<string, never>> };

// From one feature to the next a push; from or to the title cards a zoom.
const transitionAfter = (i: number): Transition => {
	const between = scenes[i].caption && scenes[i + 1].caption;
	const duration = between ? 22 : 24;
	return {
		duration,
		timing: springTiming({ config: { damping: 200 }, durationInFrames: duration }),
		presentation: between ? push() : zoomFade(),
	};
};

export const transitions: Transition[] = scenes.slice(0, -1).map((_, i) => transitionAfter(i));

// First frame of each scene: transitions overlap the end of a scene with the start of the next.
export const starts: number[] = scenes.reduce<number[]>(
	(acc, scene, i) => (i === 0 ? [0] : [...acc, acc[i - 1] + scenes[i - 1].duration - transitions[i - 1].duration]),
	[],
);

export const duration = starts[starts.length - 1] + scenes[scenes.length - 1].duration;

// When a scene's caption is on screen: from the middle of the transition in to the middle of the one out.
export const captionWindow = (i: number): [number, number] => [
	i === 0 ? 0 : starts[i] + transitions[i - 1].duration / 2,
	i === scenes.length - 1 ? duration : starts[i + 1] + transitions[i].duration / 2,
];
