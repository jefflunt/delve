T001 create `delve transform` command for LLM-based markdown generation
| add CLI command `transform` mirroring crawl args: url, depth, adapter options
| reuse spider to fetch pages; disable deterministic markdown conversion
| ensure raw html still saved to `content_raw/`
| update spider logging: print each saved raw file path under `content_raw/` instead of the source url (LLM infers corresponding `content/*.md` target)
| do not attempt markdown conversion in code
| save placeholder empty .md files in `content/` matching fetched pages
