# `soak` design document

## overview

a command-line tool for scaping documents such as the web, with a focus on
converting content to markdown to make it easily ingestible by llms.

### usage

```
template:
  soak <mode> <resource> [depth]

example:
  soak crawl https://example.com 3
```

* `crawl`: this mode starts at the specified `resource` and crowls outward in
  all directions to any other referenced documents to a maximum of `depth` steps
  away from the starting point

## tech stack

- **language:** ruby
- **http client:** `faraday`
- **html parsing & cleaning:** `nokogiri`
- **content extraction:** the `readability` gem for automatically identifying
  and extracting the primary content of a page
- **html-to-markdown conversion:** `reverse_markdown` for a conversion of the
  cleaned HTML into Markdown.
- **cli framework:** `thor`
- **concurrency:** plain old ruby `Thread`, since the project will be heavily
  i/o bound

## main components

### `cli` (the user interface)

- **responsibility:** parse command-line arguments and orchestrate the other components
- **implementation:** use `thor` to define commands
  - `soak <url> <n>`: the main command for spidering from a url outwards by
    `n` levels (default to 2 levels)

### `fetcher` (the raw content reader)

- **responsibility:** fetch the raw html from a url.
- **implementation:** a class that uses `faraday` to handle http get requests.
  it should be configured to handle redirects, set a user-agent, and manage
  basic error handling (e.g., logging a warning for 4xx/5xx responses). it will
  be executed within a thread pool managed by `concurrent-ruby`.

### `html_crawler` (the spider)

- **responsibility:** manage the queue of urls to visit and orchestrate the
  downloading and processing workflow.
- **implementation:**
  - maintain a `queue` of urls to be processed and a `set` of urls that have
    already been visited to avoid infinite loops.
  - start with the initial url. for each url:
    1.  pop a url from the queue.
    2.  dispatch a `downloader` job to the thread pool.
    3.  once downloaded, the `cleaner` extracts and saves the content.
    4.  add the new, unvisited links to the queue

### `html_cleaner` (the brains)

- **responsibility:** take raw html, parse it, clean it, extract content and
  links, and present just the main content
- **implementation:** this is the core logic.
  1.  **parse:** use `nokogiri` to turn the raw html string into a traversable
      document object.
  2.  **extract content:** use the `readability` gem to find the main article
      body. this is highly effective for articles and blog posts, as it strips
      out navigation, sidebars, and ads.
  3.  **extract links for crawling outbound links:** from the *original,
      uncleaned* nokogiri document, extract all `href` attributes from `<a>`
      tags. filter these to get absolute urls that are on the same domain as the
      source url.
  4.  **convert to markdown:** pass the cleaned html snippet from step 2 to
      `reverse_markdown` to get the final output.

### `saver` (saves the content to the file system)

- **responsibility:** save the processed markdown content to the filesystem.
- **implementation:** a simple class that takes markdown content and a source
  url. it will generate a clean filename from the url (e.g.,
  `https://example.com/foo/bar` -> `content/foo-bar.md`) and save it in the specified
  output directory. heirarchies of pages (based on their relative path) will be
  stored in child folders, and related links (i.e. that change relative paths,
  or jump to other domains/subdomains) are stored in a `related/` folder with a
  logic structure of their own.

## project structure

```
soak/
├── Gemfile
├── Gemfile.lock
├── bin/
│   └── soak                # executable cli script
└── lib/
    └── soak                # main code module
        ├── cli.rb
        ├── saver.rb
        ├── html/           # processing of html documents
        │   ├── fetcher.rb
        │   └── cleaner.rb
        └── crawlers/       # various crawler strategies
            └── spider.rb
```
