# soak design 

## 1. Overview

The goal is to build a command-line tool for scraping web pages, cleaning their content, and saving them as Markdown. The tool will support two main modes: a "spider" mode to crawl a site to a specified depth, and a "wiki" mode to download a structured hierarchy of pages.

## 2. Technology Stack (Ruby)

This project is well-suited for Ruby, leveraging its strong ecosystem of libraries for web scraping and CLI development.

- **HTTP Client:** `Faraday` for its flexible, middleware-based approach to making HTTP requests.
- **HTML Parsing & Cleaning:** `Nokogiri` for its speed and power in parsing and manipulating HTML documents.
- **Content Extraction:** A Ruby port of Mozilla's `Readability` library (e.g., the `readability` gem) for automatically identifying and extracting the primary content of a page.
- **HTML-to-Markdown Conversion:** `reverse_markdown` for a straightforward conversion of the cleaned HTML into Markdown.
- **CLI Framework:** `Thor` for building a robust and user-friendly command-line interface.
- **Concurrency:** `concurrent-ruby` to manage a thread pool for efficiently downloading multiple pages at once.

## 3. Proposed Architecture

The application can be broken down into several distinct components, each with a clear responsibility.

#### a. `CLI` (The User Interface)

- **Responsibility:** Parse command-line arguments and orchestrate the other components.
- **Implementation:** Use `Thor` to define commands.
  - `scraper crawl <url> --depth <N>`: The main command for spidering. It will kick off the crawling process starting at the given URL.
  - `scraper wiki <url> --next-selector <css_selector>`: The command for downloading a sequence of pages, like a wiki. The user provides a CSS selector that points to the "Next Page" link.
- **Options:**
  - `--output-dir`: Specify where to save Markdown files.
  - `--content-selector`: An optional CSS selector to manually specify the main content area, overriding automatic detection.
  - `--concurrency`: Number of parallel download threads.

#### b. `Downloader` (The Fetcher)

- **Responsibility:** Fetch the raw HTML from a URL.
- **Implementation:** A class that uses `Faraday` to handle HTTP GET requests. It should be configured to handle redirects, set a user-agent, and manage basic error handling (e.g., logging a warning for 4xx/5xx responses). It will be executed within a thread pool managed by `concurrent-ruby`.

#### c. `Processor` (The Brains)

- **Responsibility:** Take raw HTML, parse it, clean it, extract content and links, and convert it to Markdown.
- **Implementation:** This is the core logic.
  1.  **Parse:** Use `Nokogiri` to turn the raw HTML string into a traversable document object.
  2.  **Extract Content:**
      - **Automatic (Default):** Use the `readability` gem to find the main article body. This is highly effective for articles and blog posts, as it strips out navigation, sidebars, and ads.
      - **Manual (Override):** If the user provides a `--content-selector`, use that `Nokogiri` selector to grab a specific part of the page. This is more reliable for sites with non-standard layouts.
  3.  **Extract Links (for `crawl` mode):** From the *original, uncleaned* Nokogiri document, extract all `href` attributes from `<a>` tags. Filter these to get absolute URLs that are on the same domain as the source URL.
  4.  **Convert to Markdown:** Pass the cleaned HTML snippet from step 2 to `reverse_markdown` to get the final output.

#### d. `Crawler` (The Spider)

- **Responsibility:** Manage the queue of URLs to visit and orchestrate the downloading and processing workflow.
- **Implementation:**
  - Maintain a `Queue` of URLs to be processed and a `Set` of URLs that have already been visited to avoid infinite loops.
  - Start with the initial URL. For each URL:
    1.  Pop a URL from the queue.
    2.  Dispatch a `Downloader` job to the thread pool.
    3.  Once downloaded, the `Processor` extracts the content (which is saved) and new links.
    4.  Add the new, unvisited links to the queue, respecting the `--depth` limit.

#### e. `Storage` (The Writer)

- **Responsibility:** Save the processed Markdown content to the filesystem.
- **Implementation:** A simple class that takes Markdown content and a source URL. It will generate a clean filename from the URL (e.g., `https://example.com/foo/bar` -> `foo-bar.md`) and save it in the specified output directory.

## 4. Project Structure

A standard Ruby gem structure would be appropriate:

```
web-scraper/
├── bin/
│   └── scraper         # Executable CLI script
├── lib/
│   ├── scraper/
│   │   ├── cli.rb
│   │   ├── crawler.rb
│   │   ├── downloader.rb
│   │   ├── processor.rb
│   │   └── storage.rb
│   └── scraper.rb      # Main module file
├── Gemfile
└── Gemfile.lock
```

## 5. Next Steps

1.  **Setup:** Initialize the project structure and `Gemfile` with the necessary gems.
2.  **Core Logic:** Start by implementing the `Downloader` and `Processor`. Test them with a single, hardcoded URL to ensure the content extraction and Markdown conversion work as expected.
3.  **CLI:** Build the `Thor`-based CLI to accept a URL and pass it to the core logic.
4.  **Crawler:** Implement the crawling logic with the URL queue, visited set, and depth limiting.
5.  **Concurrency:** Integrate `concurrent-ruby` to parallelize the download tasks.
