// AGENT-NOTE: node --require preload that registers the Lean grammar into
// pi's highlight.js instance. highlight.js (pinned 10.7.3 by pi) ships no
// Lean grammar; highlightjs-lean@1.0.0 is the factory-form grammar compatible
// with hljs 10.x/11.x. Runs at node startup BEFORE pi's dist loads, so the
// singleton hljs instance pi reads already has 'lean'/'lean4' registered.
//
// Enabled via NODE_OPTIONS="--require=$HOME/.pi/agent/lean-highlight-preload.cjs"
// (see infra-land prep-pi-ds4; must also be set for cc-connect-spawned pi).
//
// Fail-safe: if the grammar is missing (e.g. global install not yet set up),
// log to stderr and continue — pi must still boot without Lean highlighting.
try {
	const hljs = require("/Users/utensil/.bun/install/global/node_modules/highlight.js/lib/index.js");
	const leanGrammar = require("/Users/utensil/.bun/install/global/node_modules/highlightjs-lean");
	hljs.registerLanguage("lean", leanGrammar);
	hljs.registerLanguage("lean4", leanGrammar);
} catch (e) {
	process.stderr.write(`[lean-highlight-preload] skip: ${e.message}\n`);
}
