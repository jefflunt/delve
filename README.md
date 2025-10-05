# `delve`

## overview

`delve` is a command-line tool for scraping documents such as the web, focusing on collecting raw html (plus confluence representations) that can later be converted to markdown by llms.

### usage

#### ingesting information, crawling a website.

```
template:
  delve <subcmd> <resource> [depth]

examples:
  delve crawl https://example.com 3
  delve crawl-domain https://example.com 3      # domain-limited crawl
  delve crawl-path https://example.com/docs 3   # path-limited crawl
```

#### publishing local files

```
template:
  delve publish <host> <folder> <space_id/parent_page_id>

examples:
  delve publish https://wiki.confluence.com example/docs public/docs
                ^confluence host            ^local folder of markdown files
                                                         ^confluence space
                                                                ^confluence parent page
```

* `crawl`: starts at the specified `resource` and crawls outward in all
directions.
* `crawl-domain`: same engine, applies a domain filter (effective domain match).
* `crawl-path`: same engine, applies a path prefix filter based on the start url.

## tech stack

- **language:** `ruby`
- **http client:** `faraday`
- **html parsing:** `nokogiri`
- **content handling:** raw html persisted (no built-in html→markdown conversion; external/LLM expected)
- **cli framework:** `thor`

## project structure

```
delve/
├── Gemfile
├── bin/
│   └── delve
└── lib/
    └── delve
        ├── cli.rb                  # main program
        ├── spider.rb               # unified crawler with filter modes
        ├── saver.rb
        ├── fetcher.rb              # dispatcher: decides adapter (html vs confluence)
        ├── publisher.rb            # dispatcher: decides adapter publisher vs noop
        ├── config.rb               # config loader/helpers + validation
        ├── fetch_result.rb         # FetchResult struct
        ├── fetch_logger.rb         # centralized logging
        ├── exit_status.rb          # exit status constants
        └── adapters/
            ├── confluence/
            │   ├── client.rb
            │   ├── fetcher.rb
            │   ├── markdown_converter.rb  # used only by publisher
            │   └── publisher.rb
            └── html/
                └── fetcher.rb
```

## for developers

the high-level control flow of the application is designed to be simple and
extensible. the main components interact in the following sequence:

```ascii
 [ cli ]
    |
    `--> [ spider ] (with filter)
           |
           | (for each url)
           v
         [ fetcher (dispatcher) ] --(is it confluence?)--> [ Confluence::Fetcher ]
           |                                                     |
           | (default)                                           |
           v                                                     |
         [ Html::Fetcher ]                                       |
           |                                                     |
           v                                                     |
         (raw html saved) <--------------------------------------+
            |
            v
         [ Saver (raw + placeholder) ]
```

- **cli:** the entry point. it parses user arguments and instantiates the
  spider with the appropriate filter.
- **spider:** manages the queue of urls to visit and orchestrates fetching and saving raw content for each url.
- **fetcher (dispatcher):** selects adapter: generic web vs confluence.
- **saver:** writes raw html under `content_raw/` plus an empty placeholder `.md` under `content/` for later LLM conversion.
- **publisher:** converts local markdown (via kramdown) and publishes to confluence (if configured) or no-ops.
- **config:** central place for loading and querying configuration.
- **fetch result + logger:** fetch operations return a lightweight `FetchResult`
  struct (url, content, links, status, type, error). logging is centralized so
  each line of crawl output shows the source type and status in fixed-width form.

## configuration

`delve` looks for an optional file at `config/delve.yml`. this file is not
required for generic html crawling, but is needed for features like publishing
and confluence-specific fetching.

`config/delve.yml` is intentionally minimal. an example is provided at
`config/delve.yml.example`:

```yaml
confluence:
  "your-instance.atlassian.net":
    username: "your-email@example.com"
    api_token: "your-confluence-api-token"
    space_key: "YOUR_SPACE_KEY"
```

### fields

- `confluence`: a mapping of confluence hostnames to credentials.
  - each key must exactly match the hostname portion of the urls you intend to
    crawl or publish to (e.g., `your-instance.atlassian.net`).
  - `username`: the confluence/cloud email login.
  - `api_token`: an api token generated from your atlassian account.
  - `space_key`: the target space key used when publishing pages (not required just to crawl/read).

### erb support

- the config file is processed through ERB before yaml parsing.
- you can embed dynamic values, e.g.:
  ```yaml
  confluence:
    <%= ENV['CONF_HOST'] %>:
      username: <%= ENV['CONF_USER'].inspect %>
      api_token: <%= ENV['CONF_TOKEN'].inspect %>
  ```
- avoid executing arbitrary code; only simple substitutions are recommended.

### behavior

- if the file does not exist, confluence functionality is skipped gracefully.
- when crawling: a url whose host matches a configured confluence host will use the `Confluence::Fetcher`; otherwise the generic `Html::Fetcher` is used. All content is saved raw (no internal markdown conversion).
- when publishing: only hosts present under `confluence` are supported; others
  will log a warning and no-op.
- config validation runs at load time; any structural errors are printed and the
  process exits with a non-zero status (see exit statuses section).

### logging format

- each fetched url is logged on one line: `TYPE  STATUS URL`
- `TYPE` is fixed-width (e.g., `web`, `confl`).
- `STATUS` is the numeric http status (or `0` if the request failed before a response).
- this stable format is designed for easy parsing / piping.

### exit statuses

- currently defined (subject to expansion):
  - `2`: configuration invalid (schema violation or missing required keys).

### security / git hygiene

- `config/delve.yml` is ignored by git (see `.gitignore`). keep credentials out of source control.
- use the provided `config/delve.yml.example` as a template for collaborators.

