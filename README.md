# Day5

A Rails app for tracking books and reviews: users sign up, list books they own (with one or more genres), and other users can rate/review those books.

## Features

- **Authentication** — self-service sign-up/sign-in built on Rails 8's built-in `generate authentication` (no Devise/Sorcery). Email/password login, session management, and password reset via token.
- **Books** — owner-scoped CRUD. Anyone (logged in or not) can browse and view books; only the owner can edit or delete theirs.
- **Genres** — many-to-many with books (`Book` <-> `BookGenre` <-> `Genre`); a book must have at least one genre.
- **Reviews** — logged-in users can leave a 1–5 star rating and body text on any book, nested under `books/:book_id/reviews`. Business rules beyond plain ownership:
  - a book's owner can't review their own book
  - a user can only review a given book once (enforced by validation and a unique DB index)

## Stack

- Ruby 3.4.9, Rails 8.1
- SQLite3 for all databases (primary, cache, queue, cable) — files under `storage/`
- Solid Cache / Solid Queue / Solid Cable (no Redis)
- Propshaft for assets, importmap-rails for JS (no Node/bundler build step), Turbo + Stimulus (Hotwire)
- Puma + Thruster, deployed via Kamal (see `config/deploy.yml`, `.kamal/`)

## Getting started

```
bin/setup              # installs deps, prepares the db, starts the server (--skip-server to skip that step)
bin/dev                 # starts the Rails server
```

## Tests

The Minitest suite under `test/` is authoritative and what CI runs:

```
bin/rails db:test:prepare test        # run the test suite
bin/rails test test/models/foo_test.rb              # a single test file
bin/rails test test/models/foo_test.rb:12           # a single test at a line
bin/rails db:test:prepare test:system               # system tests (Capybara + Selenium)
```

An `rspec-rails` setup also exists under `spec/` (not yet wired into CI):

```
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/requests/books_spec.rb
```

## Lint & security scans

```
bin/rubocop                  # Omakase Rails styling (rubocop-rails-omakase)
bin/rubocop -A                # auto-correct

bin/brakeman --no-pager       # static analysis for Rails vulnerabilities
bin/bundler-audit              # known-vulnerability scan of gem dependencies
bin/importmap audit            # vulnerability scan of JS deps pinned in config/importmap.rb
```

## CI

`.github/workflows/ci.yml` runs on every PR/push to `main`: `scan_ruby` (brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (rubocop), `test`, and `system-test`.

## Console / db

```
bin/rails console
bin/rails db:migrate
bin/rails db:seed
```
