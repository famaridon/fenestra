// Pixel geometry of the fake displays, and the Fenestra zones computed on them.

export type Rect = { x: number; y: number; w: number; h: number };

export const MENU_BAR = 30;
export const GAP = 10;

// The display used by every single-display scene.
export const SCREEN: Rect = { x: 210, y: 60, w: 1500, h: 844 };

export type Zone =
	| 'left'
	| 'right'
	| 'top'
	| 'bottom'
	| 'topLeft'
	| 'topRight'
	| 'bottomLeft'
	| 'bottomRight'
	| 'full';

// Visible area of a display: below the menu bar, inside the gaps.
export const workArea = (s: Rect): Rect => ({
	x: s.x + GAP,
	y: s.y + MENU_BAR + GAP,
	w: s.w - 2 * GAP,
	h: s.h - MENU_BAR - 2 * GAP,
});

export const zone = (s: Rect, z: Zone): Rect => {
	const a = workArea(s);
	const halfW = (a.w - GAP) / 2;
	const halfH = (a.h - GAP) / 2;
	const right = a.x + halfW + GAP;
	const bottom = a.y + halfH + GAP;
	switch (z) {
		case 'full':
			return a;
		case 'left':
			return { x: a.x, y: a.y, w: halfW, h: a.h };
		case 'right':
			return { x: right, y: a.y, w: halfW, h: a.h };
		case 'top':
			return { x: a.x, y: a.y, w: a.w, h: halfH };
		case 'bottom':
			return { x: a.x, y: bottom, w: a.w, h: halfH };
		case 'topLeft':
			return { x: a.x, y: a.y, w: halfW, h: halfH };
		case 'topRight':
			return { x: right, y: a.y, w: halfW, h: halfH };
		case 'bottomLeft':
			return { x: a.x, y: bottom, w: halfW, h: halfH };
		case 'bottomRight':
			return { x: right, y: bottom, w: halfW, h: halfH };
	}
};

// A free-floating window, positioned in fractions of the work area.
export const floating = (s: Rect, fx: number, fy: number, fw: number, fh: number): Rect => {
	const a = workArea(s);
	return { x: a.x + a.w * fx, y: a.y + a.h * fy, w: a.w * fw, h: a.h * fh };
};
