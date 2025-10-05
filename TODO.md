T001 create `delve transform` command for LLM-based markdown generation
- add CLI command `transform` mirroring crawl args: url, depth, adapter options
- reuse spider to fetch pages; disable deterministic markdown conversion
- ensure raw html still saved to `content_raw/`
- after fetch, output manifest (stdout + file) listing new/updated raw files
- do not attempt markdown conversion in code
- save placeholder empty .md files in `content/` matching fetched pages (optional?)
- document workflow in README (brief) and new docs/llm_transform.md (optional follow-up)

