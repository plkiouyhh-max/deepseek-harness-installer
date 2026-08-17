/**
 * dsh-minimal-banner: echo the minimal preset's persona line as a visible
 * context message at the start of every minimal-mode session.
 *
 * The persona row (@deepseek-ai/dsh-persona) sends the line as the system
 * prompt - invisible in the chat UI. This plugin additionally injects the
 * same line as a plugin-sourced user message on turn 1 / step 1, which the
 * web conversation renders as a context row at the top of the session.
 *
 * Mounted as a row inside the minimal agent preset, so it only runs in
 * minimal mode. Modelled after @deepseek-ai/dsh-time-context.
 */

import z from "@deepseek-ai/schemastery";

/** Cordis plugin name used by loader diagnostics and message provenance. */
const name = "minimal-banner";

/** The agent registry that owns pre-step processing. */
const inject = ["agents"];

const DEFAULT_TEXT = "You are a helpful software engineer assistant.";

/** Runtime schema for the banner row. */
const Config = z.object({
	text: z.string().default(DEFAULT_TEXT)
});

/** Build one frozen user-role message without depending on @deepseek-ai/dsh-llm. */
function createUserMessage(content, source) {
	return Object.freeze({
		id: crypto.randomUUID(),
		role: "user",
		content: Object.freeze(content),
		source: Object.freeze(source)
	});
}

/** True when this session already shows a banner injection. */
function hasBanner(agent) {
	for (const event of agent.session.events) {
		if (event.type === "user/message"
			&& event.data.source
			&& event.data.source.kind === "plugin"
			&& event.data.source.plugin === name) return true;
	}
	return false;
}

/**
 * Register a prepended pre-step listener that injects the banner once,
 * at the very first step of the very first turn of a session.
 * @param ctx - plugin context; the listener is disposed with it.
 * @param config - the banner text (defaults to the persona line).
 */
function apply(ctx, config) {
	const text = config?.text ?? DEFAULT_TEXT;
	ctx.on("agent/pre-step", async ({ agent, turn, step, signal }, next) => {
		const decision = await next();
		if (decision.kind === "reject" || signal?.aborted) return decision;
		if (turn !== 1 || step !== 1) return decision;
		if (hasBanner(agent)) return decision;
		return {
			kind: "enter",
			messages: [...decision.messages, createUserMessage(
				Object.freeze([{ type: "text", text }]),
				Object.freeze({ kind: "plugin", plugin: name, form: "banner" })
			)]
		};
	}, { prepend: true });
}

export { Config, DEFAULT_TEXT, apply, inject, name };
