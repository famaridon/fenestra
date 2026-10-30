import { Easing, interpolate } from 'remotion';
import type { Rect } from './geometry';

// Fenestra applies zones almost instantly: a short, decelerating move.
export const SNAP = Easing.bezier(0.2, 0.9, 0.25, 1);
// Pointer moves: smooth start and stop.
export const MOVE = Easing.inOut(Easing.cubic);

// A stop is [frame, value] with an optional easing for the segment that ends there.
export type Stop<T> = [number, T, ((t: number) => number)?];

const tween = (frame: number, stops: Stop<number>[]): number => {
	if (frame <= stops[0][0]) return stops[0][1];
	for (let i = 1; i < stops.length; i++) {
		const [f0, v0] = stops[i - 1];
		const [f1, v1, easing = MOVE] = stops[i];
		if (frame <= f1) {
			return interpolate(frame, [f0, f1], [v0, v1], { easing });
		}
	}
	return stops[stops.length - 1][1];
};

export const num = tween;

export const rect = (frame: number, stops: Stop<Rect>[]): Rect => {
	const pick = (k: keyof Rect) => tween(frame, stops.map(([f, r, e]) => [f, r[k], e]));
	return { x: pick('x'), y: pick('y'), w: pick('w'), h: pick('h') };
};

export type Point = { x: number; y: number };

export const point = (frame: number, stops: Stop<Point>[]): Point => ({
	x: tween(frame, stops.map(([f, p, e]) => [f, p.x, e])),
	y: tween(frame, stops.map(([f, p, e]) => [f, p.y, e])),
});

// Opacity that fades in at `from` and out at `to` (if given).
export const fade = (frame: number, from: number, to = Infinity, length = 6): number => {
	const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
	const fadeIn = interpolate(frame, [from, from + length], [0, 1], clamp);
	return to === Infinity ? fadeIn : Math.min(fadeIn, interpolate(frame, [to, to + length], [1, 0], clamp));
};

// Title bar grab point of a window, for the pointer.
export const grab = (r: Rect, fx = 0.5): Point => ({ x: r.x + r.w * fx, y: r.y + 16 });

// A rect moved so that its grab point follows the pointer.
export const dragged = (r: Rect, from: Point, to: Point): Rect => ({
	...r,
	x: r.x + to.x - from.x,
	y: r.y + to.y - from.y,
});
