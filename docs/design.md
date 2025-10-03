# `soak` design document

## overview

a command-line tool for scaping the web, with a focus on converting content to
markdown to make it easily ingestible by llms.

there are two main modes:

1. `spider`: to crawl from a URL outwards
2. `diver`: to download a hierarchical set of pages, such as those often found in
   a wiki

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

### `cleaner` (the brains)

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

### `crawler` (the spider)

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

### `saver` (saves the content to the file system)

- **responsibility:** save the processed markdown content to the filesystem.
- **implementation:** a simple class that takes markdown content and a source
  url. it will generate a clean filename from the url (e.g.,
  `https://example.com/foo/bar` -> `foo-bar.md`) and save it in the specified
  output directory. heirarchies of pages (based on their relative path) will be
  stored in child folders, and related links (i.e. that change relative paths,
  or jump to other domains/subdomains) are stored in a `related/` folder with a
  logic structure of their own.

## 4. project structure

a standard ruby gem structure would be appropriate:

```
soak/
├── bin/
│   └── soak            # executable cli script
├── lib/
│   ├── soak/
│   │   ├── cli.rb
│   │   ├── crawler.rb
│   │   ├── fetcher.rb
│   │   ├── cleaner.rb
│   │   └── storage.rb
│   └── soak.rb         # main module file
├── Gemfile
└── Gemfile.lock
```
