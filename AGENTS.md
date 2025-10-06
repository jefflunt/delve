# agent conventions

this document outlines the coding and documentation conventions for the `delve`
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

## planning

- the `TODO.md` file contains tasks to be completed in this repository
  - do not start a task until asked to start
  - top-level tasks are defined by a task ID ('Txxx', e.g. `T001`), followed by
    a short description
  - sub-tasks start on a newline and have a dash ('-'), followed by a general
    description
  - when asked to complete a task I'll refer to it by its top-level task ID
    (e.g. "please complete task T003")
  - when you complete one or more sub-tasks, replace the dash ('-') with a pipe
    ('|') to indicate that you believe that subtask is done
  - there should be exactly one blank line between top-level tasks
  - when starting a new task:
    - check the current state of the repo, and make sure that there aren't any
      uncommitted changes. if there are uncommitted changes, simply abort and
      let me know.
    - create a new branch named after the task, and make sure to branch off of
      `main`
    - commit your changes as you go: that is, do an incremental commit with
      every subtask, even if the code isn't fully working yet
    - at the end of the task, test the code again to ensure it looks like it's
      working correctly

## building

be methodical, planning each step carefully along the way. it is better to have
more, smaller subtasks that are easy to complete than fewer, large tasks that
are vague and undefined.

- before starting work on a new task, review the subtasks alert me to anything
  you feel needs more clarity

## asking for help

if you find yourself getting stuck in a debug loop and can't figure out how to
get out of it, ask for help. when asking for help, try to frame the challenge
using the MCR method (see `mcr_method.md`)
