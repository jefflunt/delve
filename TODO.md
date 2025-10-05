T001 create `delve transform` command for LLM-based markdown generation
| add CLI command `transform` mirroring crawl args: url, depth, adapter options
| reuse spider to fetch pages; disable deterministic markdown conversion
| ensure raw html still saved to `content_raw/`
| update spider logging: print each saved raw file path under `content_raw/` instead of the source url (LLM infers corresponding `content/*.md` target)
| do not attempt markdown conversion in code
| save placeholder empty .md files in `content/` matching fetched pages

T002 enhance confluence fetcher for full page fidelity
| request multiple representations (export_view, view, storage) and select best
| add attachment pagination fetch (filename, download link, size, media type)
| paginate child pages beyond default limit
| extend inline link extraction to ac:link / ri:page references
| add content length + chosen representation to log output
| add optional pretty_raw formatting (newline after block tags) controlled by config flag
| fallback: if export_view length < 70% of storage length use storage

T003 make `delve crawl` raw-only (unify with prior transform)
| remove `transform` command from CLI
| update spider to remove markdown conversion branch
| delete obsolete markdown conversion classes (html adapter converter, publisher pieces)
| ensure crawl outputs raw file paths like previous transform
| verify `bin/delve crawl https://jefflunt.com` exit 0
| update README removing transform references

T004 update crawl-domain and crawl-path to raw-only
| update commands to use unified raw behavior
| retain domain/path filtering logic
| ensure logging lists raw file paths
| verify sample runs exit 0
