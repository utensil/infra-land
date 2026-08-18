import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Container, Image, Spacer, Text } from "@earendil-works/pi-tui";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// AGENT-NOTE: show_image — display an image file inline in the TUI for the
// human operator.
//
// Two paths:
//  1. show_image tool — the model calls it; result renders in the transcript.
//  2. /show-image <path> command — the human triggers it directly; the message
//     is rendered by a registered custom renderer (registerMessageRenderer),
//     because the DEFAULT custom-message renderer only draws `text` content
//     blocks and silently DROPS `image` blocks. The renderer below emits the
//     pi-tui `Image` component (Kitty/iTerm2 graphics protocol).
//
// The image is NOT sent to the model (DeepSeek V4 is text-only); it renders
// terminal-side for the human.
const CUSTOM_TYPE = "show-image-result";

export default function (pi: ExtensionAPI) {
	const MIME_BY_EXT: Record<string, string> = {
		".png": "image/png",
		".jpg": "image/jpeg",
		".jpeg": "image/jpeg",
		".gif": "image/gif",
		".webp": "image/webp",
		".bmp": "image/bmp",
	};

	async function loadImage(path: string): Promise<{ ok: true; data: string; mimeType: string } | { ok: false; message: string }> {
		const absolutePath = path.startsWith("/") ? path : join(process.cwd(), path);
		const ext = absolutePath.slice(absolutePath.lastIndexOf(".")).toLowerCase();
		const mimeType = MIME_BY_EXT[ext];
		if (!mimeType) {
			return { ok: false, message: `Unsupported image extension: ${absolutePath}` };
		}
		try {
			const buffer = await readFile(absolutePath);
			return { ok: true, data: buffer.toString("base64"), mimeType };
		} catch (e) {
			const msg = e instanceof Error ? e.message : String(e);
			return { ok: false, message: `Could not read image [${absolutePath}]: ${msg}` };
		}
	}

	// Custom renderer: draw the label + the Image component. Without this, the
	// default custom-message renderer drops image content blocks entirely.
	pi.registerMessageRenderer(CUSTOM_TYPE, (message, _options, theme) => {
		const container = new Container();
		const label =
			typeof message.content === "string"
				? message.content
				: (message.content ?? [])
						.filter((c) => c.type === "text")
						.map((c) => c.text)
						.join("\n");
		container.addChild(new Text(theme.fg("accent", label || "show-image"), 0, 0));
		const blocks = (message.content ?? []).filter((c) => c.type === "image") as Array<{
			type: "image";
			data?: string;
			mimeType?: string;
		}>;
		for (const img of blocks) {
			if (img.data && img.mimeType) {
				container.addChild(new Spacer(1));
				container.addChild(
					new Image(
						img.data,
						img.mimeType,
						{ fallbackColor: (s: string) => theme.fg("muted", s) },
						{ maxWidthCells: 60 },
					),
				);
			}
		}
		return container;
	});

	pi.registerTool({
		name: "show_image",
		label: "Show Image",
		description:
			"Display an image file inline in the terminal for the human operator to see. " +
			"Renders via the Kitty/iTerm2 graphics protocol; the image is not sent to the model. " +
			"Use when the user asks to see/show/display an image, screenshot, diagram, or chart.",
		promptSnippet: "show_image: render an image file inline in the terminal for the operator",
		promptGuidelines: [
			"Use show_image when the user wants to see an image (screenshot, diagram, chart, generated picture) — it renders in the terminal even though the model cannot analyze it.",
		],
		parameters: Type.Object({
			path: Type.String({ description: "Path to the image file (png, jpg, jpeg, gif, webp, bmp)" }),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
			const res = await loadImage(params.path);
			if (!res.ok) {
				return { content: [{ type: "text", text: res.message }], details: {} };
			}
			return {
				content: [
					{ type: "text", text: `Showing image: ${params.path}` },
					{ type: "image", data: res.data, mimeType: res.mimeType },
				],
				details: { path: params.path, mimeType: res.mimeType },
			};
		},
	});

	// Human-triggerable command: /show-image <path> renders the image inline in
	// the transcript without involving the model at all.
	pi.registerCommand("show-image", {
		description: "Display an image file inline in the terminal (no model involvement)",
		async handler(args, _ctx) {
			const path = args.trim();
			if (!path) {
				pi.sendMessage({
					customType: CUSTOM_TYPE,
					content: [{ type: "text", text: "Usage: /show-image <path>" }],
					display: true,
				});
				return;
			}
			const res = await loadImage(path);
			if (!res.ok) {
				pi.sendMessage({
					customType: CUSTOM_TYPE,
					content: [{ type: "text", text: res.message }],
					display: true,
				});
				return;
			}
			pi.sendMessage({
				customType: CUSTOM_TYPE,
				content: [
					{ type: "text", text: `Showing image: ${path}` },
					{ type: "image", data: res.data, mimeType: res.mimeType },
				],
				display: true,
			});
		},
	});
}
