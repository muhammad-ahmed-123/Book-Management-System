---
name: rspec-conventions
description: How this project writes RSpec specs. Use whenever creating or
  editing files under spec/, or when asked to write tests for a model,
  request, or feature in this Rails app.
---
# RSpec conventions for this project
- Model specs go in spec/models, request specs in spec/requests.
- Use `describe` for the class, `context` for each scenario, and write
  `it` descriptions as full sentences.
- Prefer request specs over controller specs.
- Use `let` for test data; avoid instance variables.
- Assert both the HTTP response and the database change on create/update.