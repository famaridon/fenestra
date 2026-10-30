import type { CSSProperties, ReactNode } from 'react';
import { AbsoluteFill } from 'remotion';
import { MENU_BAR, type Rect } from '../geometry';
import { theme } from '../theme';

const box = (r: Rect): CSSProperties => ({
	position: 'absolute',
	left: r.x,
	top: r.y,
	width: r.w,
	height: r.h,
});

// Content of a scene. Transparent: the video background stays put while scenes change.
export const Stage = ({ children }: { children: ReactNode }) => (
	<AbsoluteFill style={{ fontFamily: theme.font }}>{children}</AbsoluteFill>
);

// Video background, behind every scene.
export const Backdrop = ({ children }: { children: ReactNode }) => (
	<AbsoluteFill style={{ background: theme.stage, fontFamily: theme.font }}>{children}</AbsoluteFill>
);

// A display: bezel, wallpaper and menu bar. Windows are drawn on top, in stage coordinates.
export const Display = ({ screen }: { screen: Rect }) => (
	<div
		style={{
			...box(screen),
			borderRadius: 14,
			overflow: 'hidden',
			background: theme.wallpaper,
			boxShadow: '0 0 0 6px #0b1020, 0 30px 80px rgba(0,0,0,.55)',
		}}
	>
		<div
			style={{
				height: MENU_BAR,
				background: 'rgba(255,255,255,.18)',
				backdropFilter: 'blur(20px)',
				display: 'flex',
				alignItems: 'center',
				gap: 22,
				padding: '0 18px',
				color: 'white',
				fontSize: 15,
				fontWeight: 500,
			}}
		>
			<span style={{ fontWeight: 700 }}>Finder</span>
			<span>File</span>
			<span>Edit</span>
			<span>View</span>
			<span style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 16 }}>
				<img src={theme.logo} style={{ width: 18, height: 18, borderRadius: 4 }} />
				<span>9:41</span>
			</span>
		</div>
	</div>
);

export type AppKind = 'safari' | 'notes' | 'terminal' | 'mail';

const Bar = ({ w, c = '#d9dde6', h = 10 }: { w: string | number; c?: string; h?: number }) => (
	<div style={{ width: w, height: h, borderRadius: h / 2, background: c, flexShrink: 0 }} />
);

const Content = ({ app }: { app: AppKind }) => {
	switch (app) {
		case 'terminal':
			return (
				<div style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 12 }}>
					{[60, 85, 40, 70, 55, 30].map((w, i) => (
						<div key={i} style={{ display: 'flex', gap: 10 }}>
							<Bar w={14} c="#34d399" />
							<Bar w={`${w}%`} c={i % 3 === 2 ? '#60a5fa' : '#4b5563'} />
						</div>
					))}
				</div>
			);
		case 'notes':
			return (
				<div style={{ display: 'flex', height: '100%' }}>
					<div style={{ width: '32%', background: '#f3efe2', padding: 14, display: 'flex', flexDirection: 'column', gap: 12 }}>
						{[0, 1, 2, 3].map((i) => (
							<div key={i} style={{ padding: 8, borderRadius: 6, background: i === 0 ? '#f6d860' : 'transparent' }}>
								<Bar w="80%" c={i === 0 ? '#8a6d00' : '#c9c2ab'} />
							</div>
						))}
					</div>
					<div style={{ flex: 1, padding: 20, display: 'flex', flexDirection: 'column', gap: 12 }}>
						<Bar w="50%" h={16} c="#3f3f46" />
						{[90, 75, 85, 60].map((w, i) => (
							<Bar key={i} w={`${w}%`} />
						))}
					</div>
				</div>
			);
		case 'mail':
			return (
				<div style={{ padding: 14, display: 'flex', flexDirection: 'column', gap: 8 }}>
					{[0, 1, 2, 3, 4].map((i) => (
						<div
							key={i}
							style={{
								display: 'flex',
								gap: 12,
								alignItems: 'center',
								padding: 10,
								borderRadius: 8,
								background: i === 0 ? theme.accentSoft : 'transparent',
							}}
						>
							<div style={{ width: 28, height: 28, borderRadius: 14, background: ['#f59e0b', '#10b981', '#8b5cf6', '#ef4444', '#3b82f6'][i] }} />
							<div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
								<Bar w="40%" c="#52525b" />
								<Bar w="80%" />
							</div>
						</div>
					))}
				</div>
			);
		case 'safari':
			return (
				<div style={{ padding: 22, display: 'flex', flexDirection: 'column', gap: 16 }}>
					<div style={{ height: 110, borderRadius: 10, background: `linear-gradient(120deg, ${theme.accent}, #7aa5ff)` }} />
					<Bar w="60%" h={16} c="#3f3f46" />
					<div style={{ display: 'flex', gap: 14 }}>
						{[0, 1, 2].map((i) => (
							<div key={i} style={{ flex: 1, height: 70, borderRadius: 8, background: '#eef1f6' }} />
						))}
					</div>
					{[85, 70].map((w, i) => (
						<Bar key={i} w={`${w}%`} />
					))}
				</div>
			);
	}
};

export const appColor: Record<AppKind, string> = {
	safari: '#2f6fed',
	notes: '#f2c94c',
	terminal: '#1f2937',
	mail: '#3b82f6',
};

export const AppIcon = ({ app, size }: { app: AppKind; size: number }) => (
	<div
		style={{
			width: size,
			height: size,
			borderRadius: size * 0.24,
			background: appColor[app],
			border: '1px solid rgba(0,0,0,.08)',
			display: 'flex',
			alignItems: 'center',
			justifyContent: 'center',
			color: app === 'notes' ? '#5c4700' : 'white',
			fontSize: size * 0.5,
			fontWeight: 700,
			flexShrink: 0,
		}}
	>
		{app === 'terminal' ? '>_' : app[0].toUpperCase()}
	</div>
);

export const Window = ({
	rect,
	app,
	title,
	focused = false,
	opacity = 1,
}: {
	rect: Rect;
	app: AppKind;
	title: string;
	focused?: boolean;
	opacity?: number;
}) => {
	const dark = app === 'terminal';
	return (
		<div
			style={{
				...box(rect),
				opacity,
				borderRadius: 11,
				overflow: 'hidden',
				background: dark ? '#111827' : 'white',
				boxShadow: focused
					? '0 22px 50px rgba(0,0,0,.45), 0 0 0 1px rgba(0,0,0,.25)'
					: '0 10px 28px rgba(0,0,0,.3), 0 0 0 1px rgba(0,0,0,.2)',
			}}
		>
			<div
				style={{
					height: 34,
					display: 'flex',
					alignItems: 'center',
					gap: 8,
					padding: '0 14px',
					background: dark ? '#1f2937' : '#eceef2',
					borderBottom: `1px solid ${dark ? '#0b1220' : '#d6d9e0'}`,
				}}
			>
				{['#ff5f57', '#febc2e', '#28c840'].map((c) => (
					<div key={c} style={{ width: 13, height: 13, borderRadius: 7, background: focused ? c : '#c5c8ce' }} />
				))}
				<div
					style={{
						flex: 1,
						textAlign: 'center',
						fontSize: 14,
						fontWeight: 600,
						color: dark ? '#d1d5db' : '#3f3f46',
						whiteSpace: 'nowrap',
						overflow: 'hidden',
						textOverflow: 'ellipsis',
						marginRight: 50,
					}}
				>
					{title}
				</div>
			</div>
			<div style={{ height: 'calc(100% - 34px)', overflow: 'hidden' }}>
				<Content app={app} />
			</div>
		</div>
	);
};

// Translucent zone preview shown while dragging, as in Fenestra.
export const Preview = ({ rect, opacity }: { rect: Rect; opacity: number }) => (
	<div
		style={{
			...box(rect),
			opacity,
			borderRadius: 12,
			background: 'rgba(120,160,255,.28)',
			border: '2px solid rgba(190,210,255,.9)',
			backdropFilter: 'blur(6px)',
		}}
	/>
);

export { box };
