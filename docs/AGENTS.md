# Documentation editing rules

- The root [`AGENTS.md`](../AGENTS.md) owns workflow and package-wide rules.
- Keep each engineering rule in its owning document: `ARCHITECTURE.md` for
  layers and request flow, `STANDARD.md` for API and quality contracts, and
  `GIT_FLOW.md` for branches and releases.
- Keep approved design records under `superpowers/specs/` as decision history;
  put current operating guidance in the owning engineering document.
- Do not copy the same requirement into multiple documents. Link to its source
  when another document needs to refer to it.
- Keep plans and execution notes clearly historical; do not treat them as
  current policy when they differ from the owning document.
- For documentation-only edits, check the diff, internal links, and affected
  claims. Do not run unrelated build or test gates.
