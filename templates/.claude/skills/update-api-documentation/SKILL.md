---
name: update-api-documentation
description: >-
  Keep external REST API and webhook contracts documented from a single OpenAPI
  source of truth (docs/openapi.yml), with generated Redoc HTML, validate/build
  tasks, and a CI step. Use on any change to a public route, request/response
  shape, auth scheme, or error contract.
---
# Skill: Update API Documentation (OpenAPI SSOT)

Keep external API contracts documented from a **single source of truth** (`docs/openapi.yml`),
with generated HTML, CI validation, and a recyclable guide so agents update docs alongside code.

## When to Use

- The app exposes a REST API or webhooks consumed by **external** systems.
- Documentation today is fragmented (scattered markdown, ad-hoc Swagger, a docs gem/lib).
- You want to publish to SwaggerHub and/or ship a static HTML reference (Redoc).
- **Any change** to a public route, request/response shape, auth scheme, or error contract.

## The Single Source of Truth (SSOT)

| File | Role |
|------|------|
| `docs/openapi.yml` | **SSOT** — OpenAPI 3.0, the only file edited by hand |
| `public/api-docs.html` (or `docs/api-docs.html`) | Generated HTML (Redoc). **Never edit by hand** |
| `.context/decisions/NNN-openapi-as-api-documentation-ssot.md` | ADR recording the decision |
| `<task runner>` task | `docs:validate` + `docs:build` (see per-stack examples) |
| CI step | Runs `docs:validate` on every push |

**Rule:** `docs/openapi.yml` is the contract. The HTML is a build artifact. SwaggerHub is for
mock/collaboration. Do not introduce a second source of docs.

## Scope: document external contracts only

Document **only** what external consumers depend on. Examples:

- `POST /api/v1/...` — `Authorization: Bearer <API_KEY>`
- `GET /api/v1/...` — Bearer
- `POST /webhooks/...` — per-integration header (e.g. `X-<Source>-Webhook`)

**Do not document:** admin pages, sessions/login, internal UI endpoints, background jobs
(Sidekiq/Celery/queues), health checks — unless they are a published public contract.

## Minimal OpenAPI structure

```yaml
openapi: 3.0.0
info:
  title: "{App} API"
  description: |
    External contracts. Auth:
    - REST API: Authorization: Bearer {API_KEY}
    - Webhooks: integration-specific headers
  version: 1.0.0
servers:
  - description: SwaggerHub Auto Mocking
    url: https://virtserver.swaggerhub.com/{ORG}/{APP}/1.0.0
  - description: Production
    url: https://{host}
paths: {}
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
    # one apiKey scheme per webhook header, mirroring the controllers
  schemas: {}
```

## Tasks: `docs:validate` + `docs:build`

`validate` checks the YAML parses and has the minimum structure (`openapi`, non-empty `paths`).
`build` renders `docs/openapi.yml` into self-contained HTML via the Redoc standalone bundle.
Adapt to the project's task runner — the logic is identical across stacks.

<details>
<summary>Ruby / Rails (<code>lib/tasks/docs.rake</code>)</summary>

```ruby
namespace :docs do
  OPENAPI_PATH = Rails.root.join("docs/openapi.yml")
  HTML_PATH    = Rails.root.join("public/api-docs.html")

  desc "Validate OpenAPI spec (YAML + minimal structure)"
  task validate: :environment do
    spec = YAML.load_file(OPENAPI_PATH)
    abort "[docs] invalid: missing 'openapi'" unless spec.is_a?(Hash) && spec["openapi"].present?
    abort "[docs] invalid: empty 'paths'"     unless spec["paths"].is_a?(Hash) && spec["paths"].any?
    puts "[docs] OK (#{spec['paths'].size} paths)"
  end

  desc "Generate HTML from OpenAPI (Redoc CDN)"
  task build: :validate do
    spec = YAML.load_file(OPENAPI_PATH)
    html = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <title>#{ERB::Util.html_escape(spec.dig('info', 'title') || 'API')}</title>
      </head>
      <body>
        <div id="redoc-container"></div>
        <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
        <script>
          Redoc.init(#{JSON.generate(spec)}, {}, document.getElementById("redoc-container"));
        </script>
      </body>
      </html>
    HTML
    File.write(HTML_PATH, html)
    puts "[docs] wrote #{HTML_PATH}"
  end
end
```
</details>

<details>
<summary>Node (<code>package.json</code> scripts)</summary>

```jsonc
{
  "scripts": {
    "docs:validate": "redocly lint docs/openapi.yml",
    "docs:build": "redocly build-docs docs/openapi.yml -o public/api-docs.html"
  },
  "devDependencies": { "@redocly/cli": "^1" }
}
```
</details>

<details>
<summary>Python (<code>Makefile</code> or scripts)</summary>

```makefile
docs-validate:
	python -c "import yaml,sys; s=yaml.safe_load(open('docs/openapi.yml')); \
	  sys.exit(0 if s.get('openapi') and s.get('paths') else 'invalid spec')"

docs-build:
	npx @redocly/cli build-docs docs/openapi.yml -o public/api-docs.html
```
</details>

## CI (one step in the existing workflow)

No separate workflow needed. `build` runs locally or at deploy time.

```yaml
- name: Validate OpenAPI spec
  run: <task-runner> docs:validate   # e.g. bundle exec rake docs:validate / npm run docs:validate
```

## Agent workflow — code change → OpenAPI edit

When code changes touch public contracts, map the change to the spec. **Never invent fields** —
read the controller/handler and its param permit-list / validations / serializer first.

| Code change | Edit in OpenAPI |
|-------------|-----------------|
| Routes (`/api/v1/*`, `/webhooks/*`) | `paths` — exact method + path |
| API controllers/handlers | `requestBody`, `parameters`, `security: BearerAuth` |
| Webhook controllers/handlers | `security` (header scheme) + body `schemas` |
| API auth concern/middleware | `components.securitySchemes` + `401` response |
| Webhook auth concern/middleware | header scheme + `401` response |
| Event-type enums | `enum` in the schema |
| Error message i18n/strings | `example` in the responses |

**Steps:**
1. Read the controller/handler + its `params.permit` / schema / validations (source of truth for fields).
2. Edit `docs/openapi.yml` — update `paths` and `components/schemas`.
3. Write descriptions in the project's documentation language; put real error messages in `examples`.
4. YAML strings containing `:` must be quoted — `'Error: field X is required'`.
5. Run `docs:validate` → then `docs:build`.
6. Commit `docs/openapi.yml` **and** the generated HTML together.

## Anti-patterns

- Duplicating the contract in markdown.
- Documenting internal routes (admin, sessions, UI, jobs).
- Editing the generated HTML by hand.
- Adding a second docs source (a docs gem/lib, a parallel Swagger file).
- Inventing request/response fields not present in the code.

## Integration with other skills

In skills that add an endpoint / webhook / event, add a final step:

```markdown
### N. Update OpenAPI documentation
Follow `.claude/skills/update-api-documentation/SKILL.md`.
```

In `CLAUDE.md` / project rules:

> OpenAPI SSOT: `docs/openapi.yml`. When changing `/api/v1` or `/webhooks`, follow the
> `update-api-documentation` skill, then run `docs:validate` and `docs:build`.

## Bootstrap checklist (first-time setup)

- [ ] Inventory public routes (REST + webhooks).
- [ ] Read controllers/handlers + auth concerns/middleware.
- [ ] Create `docs/openapi.yml` with `paths`, `schemas`, `securitySchemes`, `examples`.
- [ ] Add `docs:validate` + `docs:build` tasks for the project's task runner.
- [ ] Run `docs:build` → commit the HTML.
- [ ] Add the ADR (`openapi-as-api-documentation-ssot`) via `/add-decision`.
- [ ] Add the CI `docs:validate` step (optional but recommended).
- [ ] Remove legacy/duplicate docs sources.
- [ ] Update `CLAUDE.md` / editor rules to point at the SSOT.

## Per-app variables to substitute

`{App}`, `{ORG}`, `{APP}`, `{host}`, the auth env var names (e.g. `NEXUS_API_KEY`,
`WMS_WEBHOOK_TOKEN`), the list of public paths, and the OpenAPI tags (e.g. `Inventory`,
`Webhooks — WMS`).
