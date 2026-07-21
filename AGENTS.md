<!-- agnt:begin (managed by `agnt run` — do not edit inside this block) -->
agnt MCP server = browser superpowers for AI coding agents. Tools below live on the `agnt` MCP server. Call as MCP tools directly. NOT shell. NOT `agnt <tool>` CLI.

If `agnt` tools are missing from your MCP list: check `slop-mcp` — agnt may be registered there. Use `slop-mcp` `execute_tool {mcp_name:"agnt", tool_name:"...", parameters:{...}}` as fallback. Reconnect via `manage_mcps {action:"reconnect", name:"agnt"}` if cached/disconnected.

## CRITICAL: Use proc for dev servers and long-lived builds

**Never run dev servers or long-lived builds via the Bash tool.** Use the agnt `proc` MCP tool so the daemon can stream output, capture errors, and surface logs to the browser.

Bad (blocks the agent loop, no live output, no agnt integration):

```plain
Bash: npm run dev
Bash: go run ./cmd/server
Bash: cargo watch -x run
Bash: make build
```

Good (returns immediately, output streamed and captured):

```plain
proc {action: "run", id: "dev", command: "npm run dev"}
proc {action: "output", id: "dev"}     // pull recent output lines
watch {target: "process", process_id: "dev"}  // get a streaming monitor command for live tailing
```

Pattern: `proc run` to start, `proc output` to inspect, `watch` to follow live, `proc stop` to terminate. The `agnt hook check-bash` interceptor will block raw `npm run`/`yarn`/`go run`/etc. via the PreToolUse hook when wired into `~/.claude/settings.json`.

## agnt Tools (trigger → tool → skill for depth)

- errors anywhere → `get_errors {}` (legacy) / `get_incidents {}` (authoritative, pipeline on) · skill: `/agnt:check-errors`, `/agnt:error-monitor`
- dev server / process → `proc` (run/output/stop/list) · skill: `/agnt:process-proxy`
- what user sees now → `currentpage {}` · skill: `/agnt:current-page`
- reverse proxy + browser JS → `proxy` (start/list/exec/screenshot) · skill: `/agnt:dev-proxy`, `/agnt:browser-debug`
- HTTP traffic → `proxylog` (filter type/body) · skill: `/agnt:review-api`
- viewport audit → `responsive_audit` (mobile/tablet/desktop) · skill: `/agnt:responsive-check`
- headless drive → `automation` (screenshot/navigate/evaluate)

## Debugging Workflow

Broken thing → MCP tools, this order:

1. `get_incidents {}` / `get_errors {}` — first always
2. `currentpage {}` — what user sees
3. `proc {action:"output", id:"..."}` — crash/build output
4. `proxylog {action:"query", types:["error"]}` — HTTP/API fail
5. `proxy {action:"exec", id:"...", code:"..."}` — diagnostic JS
6. screenshot if visual

Browser messages include `proxy: <id>` as tool scope. Copy it into `proxy_id` (or `id` for proxy actions). A `proxy_id required` response is an argument-validation error and often lists a running proxy; it is not evidence that the dev server is down. Check `proc` status/output before claiming a process stopped.

## Common Patterns

- page blank → get_errors → proc output
- API 500 → proxylog query endpoint
- style wrong → responsive_audit + screenshot
- click dead → proxy exec → pointer-events / overlays / z-index
- crashed → proc output → restart

## Configured Scripts

- **serve**: `npx http-server . -p 9382` (autostart)

## Configured Proxies

- **app**: (linked to script 'serve')

## Process Management

- `proc {action:"list"}` — all processes + states
- `proc {action:"output", id:"..."}` — recent lines
- `proc {action:"stop", id:"..."}` then `proc {action:"run", script:"..."}` — restart
- `proxy {action:"list"}` — all proxies + states
- `proxy {action:"exec", id:"...", code:"..."}` — JS in browser
- DO NOT start already-running process/proxy

## Browser debugging helpers
Prefer __devtool.* helpers over raw document.*/window.*/getBoundingClientRect.
Call `proxy exec search: X` before writing raw JS.
Use `proxy exec describe: name` for full signature + example.
Symptom→helper (the decisive evidence is runtime state, not the source):
- z-index/layering wrong → __devtool.getStacking (stackingRoot + rootTrigger), not a bigger z-index.
- position:fixed scrolls/mispositions → __devtool.getContainer (trappedBy ancestor).
- element clipped/hidden → __devtool.findOverflows / isVisible.

### logging
- `log(message, level?, data?)` — Send a custom log message to the proxy server
### screenshot
- `screenshot(nameOrOptions?, selector?)` — Capture a screenshot of the page or a specific element
### inspection
- `inspect(selector)` — Get comprehensive inspection of an element (combines multiple inspection calls)
- `getElementInfo(selector)` — Get comprehensive information about an element
- `getComputed(selector, properties?)` — Get computed CSS styles for an element
- `getStacking(selector)` — Get stacking context information for an element: whether it creates its own context (and via which CSS property), the nearest ancestor stacking root that its z-index actually resolves against, the property that made that root a context (rootTrigger), and the full ancestor chain. Use this before changing z-index — the "z-index does nothing" bug is almost always a cross-stacking-context comparison, fixed by removing/moving rootTrigger, not by a bigger number.
- `getContainer(selector)` — Resolve the containing block for a positioned element and surface the ancestor property that traps a position:fixed element (transform, filter, will-change, contain) — the distant cause behind "my fixed element scrolls away / is mispositioned" that is invisible in source.
### layout
- `findOverflows()` — Find elements causing horizontal overflow
- `findStackingContexts()` — Find every stacking context in the document, each with the exact CSS trigger(s) that created it. Detects the full spec trigger set — positioned+z-index, opacity, transform, filter, backdrop-filter, perspective, clip-path, mask, mix-blend-mode, isolation:isolate, will-change, contain, and flex/grid children with z-index — not just the obvious four. Each trigger is {property, value} so the agent sees the removable cause.
- `diagnoseLayout(selector?)` — Run comprehensive layout diagnostics
### accessibility
- `auditAccessibility()` — Run accessibility audit on the page
- `getA11yInfo(selector)` — Get accessibility information for an element
- `getContrast(selector)` — Calculate color contrast ratio for text
### audit
- `auditPageQuality()` — Comprehensive page quality audit
- `auditDOMComplexity()` — Analyze DOM complexity and depth
### interactions
- `interactions.getLastClickContext(trailMs?)` — Get last click with surrounding mouse trail
### mutations
- `mutations.highlightRecent(duration?)` — Visually highlight recently added elements
<!-- agnt:end -->
