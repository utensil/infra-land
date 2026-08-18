import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

// AGENT-NOTE: show_image — display an image file inline in the TUI for the
// human operator. Returns a `{ type: "image" }` content block, which pi's
// tool-result renderer draws via the Kitty/iTerm2 graphics protocol. The
// image is NOT sent to the model (DeepSeek V4 is text-only); pi's
// normalizeToolResultImages auto-resizes it on the way into session history.
//
// No pi-internal imports: read → base64 → content block is the whole
// contract (the earlier attempt imported dist/utils/image-process.js, a
// non-exported subpath — that's why it failed to load).
export default function (pi: ExtensionAPI) {
	const MIME_BY_EXT: Record<string, string> = {
		".png": "image/png",
		".jpg": "image/jpeg",
		".jpeg": "image/jpeg",
		".gif": "image/gif",
		".webp": "image/webp",
		".bmp": "image/bmp",
	};

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
			const absolutePath = params.path.startsWith("/")
				? params.path
				: join(process.cwd(), params.path);
			const ext = absolutePath.slice(absolutePath.lastIndexOf(".")).toLowerCase();
			const mimeType = MIME_BY_EXT[ext];
			if (!mimeType) {
				return {
					content: [{ type: "text", text: `Unsupported image extension: ${absolutePath}` }],
					details: {},
				};
			}
			let data: string;
			try {
				const buffer = await readFile(absolutePath);
				data = buffer.toString("base64");
			} catch (e) {
				const msg = e instanceof Error ? e.message : String(e);
				return {
					content: [{ type: "text", text: `Could not read image [${absolutePath}]: ${msg}` }],
					details: {},
				};
			}
			return {
				content: [
					{ type: "text", text: `Showing image: ${absolutePath}` },
					{ type: "image", data, mimeType },
				],
				details: { path: absolutePath, mimeType },
			};
		},
	});
}
