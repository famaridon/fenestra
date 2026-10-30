// Every on-screen text, per language. Add a language here and in Root.tsx.

export type Lang = 'en' | 'fr';

export type CaptionKey = 'layouts' | 'mouse' | 'assist' | 'border' | 'keyboard' | 'displays';

export type Strings = {
	tagline: string;
	layouts: [string, string];
	mouse: [string, string];
	assist: [string, string];
	border: [string, string];
	keyboard: [string, string];
	displays: [string, string];
	outro: [string, string];
	windows: { safari: string; notes: string; terminal: string; mail: string };
};

export const strings: Record<Lang, Strings> = {
	en: {
		tagline: 'Windows and Ubuntu-style window snapping for macOS',
		layouts: ['Snap Layouts', 'Rest on the green button, click a zone'],
		mouse: ['Drag to an edge', 'A preview shows the zone, release to snap'],
		assist: ['Snap Assist', 'Pick another window to fill the free space'],
		border: ['Shared border', 'Resize snapped windows together'],
		keyboard: ['Keyboard shortcuts', 'Halves, quarters, full screen and restore'],
		displays: ['Multiple and vertical displays', 'Send windows across, top / bottom split in portrait'],
		outro: ['Download Fenestra', 'famaridon.github.io/fenestra'],
		windows: { safari: 'Safari — Fenestra', notes: 'Notes', terminal: 'Terminal — zsh', mail: 'Mail — Inbox' },
	},
	fr: {
		tagline: 'Le snapping de fenêtres façon Windows et Ubuntu, sur macOS',
		layouts: ['Snap Layouts', 'Survolez le bouton vert, cliquez sur une zone'],
		mouse: ['Glissez vers un bord', "Un aperçu montre la zone, relâchez pour l'appliquer"],
		assist: ['Snap Assist', "Choisissez une autre fenêtre pour remplir l'espace libre"],
		border: ['Bordure partagée', 'Redimensionnez les fenêtres ancrées ensemble'],
		keyboard: ['Raccourcis clavier', 'Moitiés, quarts, plein écran et restauration'],
		displays: ['Plusieurs écrans, écran vertical', 'Envoyez les fenêtres d’un écran à l’autre, haut / bas en portrait'],
		outro: ['Téléchargez Fenestra', 'famaridon.github.io/fenestra'],
		windows: { safari: 'Safari — Fenestra', notes: 'Notes', terminal: 'Terminal — zsh', mail: 'Mail — Boîte de réception' },
	},
};
