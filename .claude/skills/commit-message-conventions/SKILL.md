---
name: commit-message-conventions
description: How this project writes Git commit messages. Use whenever generating,
  suggesting, or formatting commit messages based on staged changes or code
  diffs in this Ruby on Rails repository.
---
# Commit Message Conventions for this project
- Follow the Conventional Commits specification: `type(scope): subject`.
- Valid types include: `feat`, `fix`, `refactor`, `perf`, `chore`, `docs`, `test`.
- Write the subject line in the imperative mood (e.g., "Add feature", not "Added feature" or "Adds feature") and keep it under 50 characters.
- Determine the `scope` based on Ruby on Rails architectural components modified (e.g., `model`, `controller`, `view`, `mailer`, `job`, `route`, `db`).
- For database migrations or schema updates, clearly state the data structure changes (e.g., `feat(db): create users table`).
- If changes involve background processing, explicitly note the ActiveJob or Redis/Sidekiq aspects.
- Include an optional body wrapped at 72 characters to explain the *why* behind complex changes, particularly for intricate ActiveRecord callbacks, N+1 query fixes, or complex business logic.