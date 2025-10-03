# `soak`

## overview

`soak` is a command-line tool for scaping documents such as the web, with a
focus on converting content to markdown to make it easily ingestible by llms.

### usage

```
template:
  soak <mode> <resource> [depth]

examples:
  soak crawl https://example.com 3
  soak crawl-domain https://example.com 3
  soak crawl-path https://example.com/docs 3
```

* `crawl`: starts at the specified `resource` and crawls outward in all
  directions.
* `crawl-domain`: crawls outward, but stays within the domain of the
  starting `resource`.
* `crawl-path`: crawls outward, but stays within the path of the starting
  `resource`.

## tech stack

- **language:** `ruby`
- **http client:** `faraday`
- **html parsing & cleaning:** `nokogiri`
- **content extraction:** `ruby-readability` gem
- **html-to-markdown conversion:** `reverse_markdown`
- **cli framework:** `thor`

## project structure

```
soak/
├── Gemfile
├── bin/
│   └── soak
└── lib/
    └── soak
        ├── cli.rb                  # the main program, effectively
        ├── saver.rb
        ├── html/                   # html processing tools
        │   ├── fetcher.rb
        │   └── cleaner.rb
        └── crawlers/               # content crawlers
            ├── spider.rb
             ├── spider_domain.rb
             └── spider_path.rb
```

## for developers

the high-level control flow of the application is designed to be simple and
extensible. the main components interact in the following sequence:

```ascii
 [ cli ]
    |
    `-> [ crawler ] (e.g., spider, spider_domain)
           |
           | (for each url)
           v
         [ fetcher (dispatcher) ] --(is it confluence?)--> [ confluence::fetcher ]
           |                                                     |
           | (default)                                           |
           v                                                     |
         [ Html::Fetcher ]                                       |
           |                                                     |
           v                                                     |
         [ Html::Cleaner ] <-------------------------------------+
           |
           v
         [ Saver ]
```

- **cli:** the entry point. it parses user arguments and instantiates the
  correct crawler.
- **crawler:** manages the queue of urls to visit and orchestrates the fetching,
  cleaning, and saving process for each url.
- **fetcher (dispatcher):** this is the brain of the content retrieval. based on
  the url's host and the `soak.yml` config, it decides whether to use the
  `Html::Fetcher` for generic web pages or the `Confluence::Fetcher` for
  confluence sites.
- **cleaner/saver:** the `Html::Cleaner` processes the fetched html, and the
  `Saver` writes the final markdown to disk.
