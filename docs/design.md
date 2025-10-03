# `soak` design document

## overview

a command-line tool for scaping documents such as the web, with a focus on
converting content to markdown to make it easily ingestible by llms.

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

- **language:** ruby
- **http client:** `faraday`
- **html parsing & cleaning:** `nokogiri`
- **content extraction:** the `readability` gem
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
        ├── cli.rb
        ├── saver.rb
        ├── html/
        │   ├── fetcher.rb
        │   └── cleaner.rb
        └── crawlers/
            ├── spider.rb
            ├── spider_domain.rb
            └── spider_path.rb
```

