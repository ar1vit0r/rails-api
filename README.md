# Rails API

Rails 8.1 API-only backend for task management: JWT-authenticated users manage tasks
grouped into categories. SQLite in every environment. Interactive docs are served at
`/api-docs`.

## Setup

Requires Ruby 3.4.4 (see `.ruby-version`).

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

The seed creates two accounts, an admin and a regular user (see `db/seeds.rb`), three
categories and a few sample tasks.

## Tests and checks

```bash
bundle exec rspec           # test suite
bundle exec rubocop         # lint
bundle exec brakeman        # static security scan
bundle exec bundler-audit   # dependency vulnerability scan
```

CI runs all four on every push and pull request to `main`.

## API docs

The OpenAPI file `swagger/v1/swagger.yaml` is generated from the request specs in
`spec/requests/`. After changing an endpoint, update its spec and regenerate:

```bash
bundle exec rake rswag:specs:swaggerize
```

## Frontend

`frontend/` is a standalone client (plain HTML/CSS/JS, no build step). Start the API
with `bin/rails server`, then open `frontend/index.html` in a browser. Opened locally it
calls `http://localhost:3000`; hosted, it calls the production API. Use `?api=<url>` to
point it elsewhere.

## Deployment

`render.yaml` describes the Render services (the API and the static frontend) and
`config/deploy.yml` configures Kamal.
