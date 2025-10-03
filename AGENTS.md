# agent conventions

this document outlines the coding and documentation conventions for the `soak`
project. as an agent working on this codebase, please adhere to these
guidelines.

## documentation (`.md` files)

- all documentation will be kept in the `docs/` directory.
- downloaded content will be stored in the `content/` directory.
- text should be written in lower-case, except for proper nouns (e.g., ruby,
  nokogiri).
- lines should be wrapped at 80 characters.
- exceptions to the 80-character limit are permitted for hyperlinks, tables,
  and code blocks where breaking lines would be impractical.

## ruby code (`.rb` files)

- all code should adhere to an 80-character line limit.
- do not use the `private` keyword for methods.
- methods intended for internal use should be prefixed with an underscore (`_`).

for example:

```ruby
class my_class
  def public_method
    # ...
    _private_helper
  end

  def _private_helper
    # this is a private method
  end
end
```

## testing
- run `bin/delve crawl https://jefflunt.com` and ensure that the exit status is `0`
