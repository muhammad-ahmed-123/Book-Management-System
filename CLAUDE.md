# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

Rails 8.1 app (`Day5`). Authentication is scaffolded via Rails 8's built-in generator (not Devise/Sorcery) and extended with self-service sign-up. Domain features so far: `Book` (owner-scoped CRUD, publicly viewable) and `Review` (per-book ratings/reviews nested under books, with extra business-rule guards beyond plain ownership). Use these as the reference patterns for any new authenticated/owned resource.

## Stack

- Rails 8.1, Ruby 3.4.9
- SQLite3 for all databases (primary, cache, queue, cable) — files live under `storage/`
- Solid Cache / Solid Queue / Solid Cable (no Redis) for caching, jobs, and Action Cable
- Propshaft for assets, importmap-rails for JS (no bundler/webpack), Turbo + Stimulus (Hotwire)
- Puma + Thruster, deployed via Kamal (see `config/deploy.yml`, `.kamal/`)

## Commands

Setup:
```
bin/setup              # installs deps, prepares db, starts server (use --skip-server to skip that step)
```

Run the dev server:
```
bin/dev                 # starts Rails server (foreman/Procfile.dev if present, else rails server)
```

Tests (RSpec — the authoritative suite, wired into CI via the `rspec` job):
```
bin/rails db:test:prepare
bundle exec rspec                              # run the full suite
bundle exec rspec spec/models/user_spec.rb     # run a single spec file
bundle exec rspec spec/requests/books_spec.rb
```

The `test/` (Minitest) suite has been removed; `spec/` is now the only and primary test suite. A project-scoped skill at `.claude/skills/rspec-conventions/SKILL.md` documents how specs under `spec/` should be written (request specs preferred over controller specs, `let` over instance variables, assert response + DB change together) — follow it for any new/updated spec.

Lint:
```
bin/rubocop              # Omakase Rails styling (rubocop-rails-omakase); config in .rubocop.yml
bin/rubocop -A           # auto-correct
```

Security scans (also run in CI):
```
bin/brakeman --no-pager     # static analysis for Rails vulnerabilities
bin/bundler-audit            # known-vulnerability scan of gem dependencies
bin/importmap audit          # vulnerability scan of JS deps pinned in config/importmap.rb
```

Console / db:
```
bin/rails console
bin/rails db:migrate
bin/rails db:seed
```

## CI

`.github/workflows/ci.yml` runs four jobs on every PR/push to `main`: `scan_ruby` (brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (rubocop), and `rspec` (the RSpec suite under `spec/`, the authoritative test suite). Match these locally before pushing.

## Testing policy

Whenever a new feature is added (models, controllers, business rules), write exhaustive test coverage for it — not just the happy path. Leave no stone unturned: cover valid/invalid inputs, every validation (presence/uniqueness/inclusion), ownership-scoped access (can't load/edit/destroy another user's record), unauthenticated-access rules, nested-resource business-rule guards (e.g. `Review`'s self-review/duplicate-review blocks), and DB-level constraints (unique-index race conditions), mirroring the depth already established for `Book`/`Review`. Follow `.claude/skills/rspec-conventions/SKILL.md` conventions for specs under `spec/` (the authoritative suite).

## UI policy

Every page/view must be responsive across mobile, tablet, and desktop screen sizes — not desktop-only. Build on the mobile-first foundation in `app/assets/stylesheets/application.css` (`container`, `site-nav`, `book-grid`, `btn`, `form-group`/`field` classes, breakpoints at 600px and 1024px) rather than inline `style=` attributes or fixed pixel widths, and reuse existing classes before adding new ones.

## Architecture notes

- Standard Rails autoloading: `app/models`, `app/controllers`, `app/jobs`, `app/mailers`, plus `config.autoload_lib` for `lib/` (excluding `lib/assets`, `lib/tasks`).
- Multiple SQLite databases are wired up in `config/database.yml` for production: `primary`, `cache`, `queue`, `cable`, each with its own migration path (`db/cache_migrate`, `db/queue_migrate`, `db/cable_migrate`). Schema files for these live at `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb`.
- JS is managed via importmap (no Node build step) — add packages with `bin/importmap pin <package>`. Stimulus controllers go in `app/javascript/controllers/` and are auto-registered via `app/javascript/controllers/index.js`.
- Recurring/background jobs are configured via Solid Queue in `config/recurring.yml`.

### Authentication

Scaffolded via Rails 8's built-in `bin/rails generate authentication` (not a gem like Devise):
- `User` (`app/models/user.rb`): `has_secure_password`; `Session`/`Book` etc. belong to it.
- `Session` (`app/models/session.rb`): one row per signed-in browser session, `belongs_to :user`.
- `Current` (`app/models/current.rb`): `ActiveSupport::CurrentAttributes` holding the request's `session`; delegates `:user`, so `Current.user` is the logged-in user (or `nil`) anywhere in a controller/view.
- `app/controllers/concerns/authentication.rb`, included in `ApplicationController`: runs `before_action :require_authentication` on **every** action of **every** controller by default, redirecting to `new_session_path` if not logged in. To make an action public, call the class method `allow_unauthenticated_access(only: [...])` in that controller (see `SessionsController`, `BooksController`). Also exposes the `authenticated?` helper for views.
- `SessionsController` / `PasswordsController`: login and token-based password reset.
- `RegistrationsController` (`resource :registration`, singular — `new`/`create` only): self-service sign-up. Mirrors `SessionsController`'s public-action/rate-limiting shape, but additionally redirects an already-authenticated visitor away from the form (unlike sign-in, re-registering while logged in has no legitimate use case). On success it calls the same `start_new_session_for` helper `SessionsController#create` uses, so sign-up auto-logs-in. `User` has `validates :email_address, presence: true, uniqueness: true` and `validates :password, length: { minimum: 8 }, allow_nil: true` (the `allow_nil` matters — `password` is `nil` on any save that doesn't set a new one, e.g. future profile edits) specifically to make these public-facing forms produce friendly validation errors instead of raw DB exceptions.
- Root page (`books#index`) shows Sign In/Sign Up when logged out, New Book/Sign Out when logged in — see `app/views/books/index.html.erb` for the `authenticated?`-gated pattern to copy for any new nav-level link.

### Ownership-scoped resources (pattern: `Book`)

`Book` (`app/models/book.rb`, `app/controllers/books_controller.rb`) is the template for any future resource where anyone can view records but only the owner can mutate theirs:
- Public actions (`index`/`show`) opt out of auth via `allow_unauthenticated_access` and query unscoped (`Book.all`, `Book.find`).
- `create` builds through the association — `Current.user.books.build(params)` — so ownership can never be set/spoofed via request params.
- Mutating actions that target an existing record (`edit`/`update`/`destroy`) load it through `Current.user.books.find_by(id: ...)`, **not** `Book.find` plus a manual ownership check — this makes it structurally impossible to load another user's record into an authorized action. A missing/not-owned id redirects (not 404) with a flash alert, so as not to reveal whether an id exists under another user.

### Nested, rule-guarded resources (pattern: `Review`)

`Review` (`app/models/review.rb`, `app/controllers/reviews_controller.rb`, nested `resources :reviews` under `resources :books`) extends the ownership pattern with extra business rules, worth copying whenever a new resource needs more than plain "own it or don't":
- No `allow_unauthenticated_access` at all — every review action requires login by default, since (unlike books) nothing about reviews needs to be public beyond being displayed inline on `books#show`.
- Two `before_action`s block invalid submissions using the *authenticated session*, never client params, so they can't be bypassed by a crafted request: `block_self_review` (a book's owner can't review their own book) and `block_duplicate_review` (a user can only review a given book once).
- "One review per user per book" is enforced at the DB level (a unique index on `[book_id, user_id]`), not just an `ActiveRecord` validation — the validation is the friendly first line of defense, the index is the non-bypassable backstop for the check-then-insert race window. A `rescue_from ActiveRecord::RecordNotUnique` catches that rare race and converts it to the same friendly redirect instead of a 500.
- `edit`/`update`/`destroy` reuse the exact `Current.user.<assoc>.find_by(id: ...)` ownership-scoped-lookup pattern from `BooksController`.
