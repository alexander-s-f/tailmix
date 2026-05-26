# Tailmix — CLAUDE.md

## Project Overview

**Tailmix** is a Ruby gem that provides a declarative, state-driven engine for managing HTML attributes (CSS classes, data attributes, ARIA roles) in Ruby UI components (Arbre, ViewComponent, Phlex, etc.). It has two halves:

- **Ruby (server-side):** A DSL that parses component definitions into an AST, compiles it to a JSON definition, and builds a runtime Facade class.
- **JavaScript (client-side):** A browser runtime (`tailmix.bundle.js`) that hydrates components from that JSON definition, manages state, handles events, and patches the DOM.

## Repository Layout

```
lib/tailmix/
  ast/
    nodes.rb           # All AST node structs (Component, StateDefinition, ElementDefinition, StyleRule, MatchRule, EventRule, Fetch, Block, Assignment, …)
    visitor.rb         # Base Visitor pattern
  compiler/
    json_generator.rb  # AST::Visitor subclass → compiles AST to a plain Ruby Hash (the "definition")
  dsl/
    component_parser.rb  # Top-level DSL: state, variant, element, boot, watch
    element_parser.rb    # Per-element DSL: on, style, match, fetch
    action_parser.rb     # Action/instruction DSL: set, toggle, dispatch, log, fetch
    effect_builder.rb    # Builds AttributeEffect AST nodes (classes, data, aria, props, html)
    match_builder.rb     # Builds MatchRule AST nodes (on arms, default)
    style_builder.rb     # Builds StyleRule AST nodes (consequent + otherwise branch)
    parser_context.rb    # Shared DSL context helpers
    expression.rb        # DSL expression helpers
  runtime/
    facade.rb            # Base Facade class (element accessor methods)
    facade_builder.rb    # Dynamically builds a Facade subclass from the compiled definition
  interpreter/
    evaluator.rb         # Ruby-side expression evaluator (mirrors JS evaluator)
    renderer.rb          # Ruby-side renderer (mirrors JS renderer)
    scope.rb             # Ruby-side scope
  visitors/
    debug_printer.rb     # Prints the AST for debugging
  component_store.rb     # Registry of component definitions (used by Rails controller)
  configuration.rb
  engine.rb              # Rails Engine; mounts DefinitionsController
  view_helpers.rb        # Rails view helpers (tailmix_component_tag, tailmix_trigger_for, …)
  version.rb

app/
  javascript/tailmix/
    runtime/
      index.js           # Entry point; auto-hydrates [data-tailmix-component] elements
      component.js       # Component class (state, render, events, persistence)
      persistence.js     # LocalStorage / SessionStorage persistence
      utils.js           # deepMerge, etc.
    interpreter/
      action_interpreter.js  # Executes compiled instruction arrays
      evaluator.js           # Evaluates compiled expression arrays
      renderer.js            # Calculates element attributes from definition + state
      dom_patcher.js         # Applies rendered attributes to real DOM nodes
      scope.js               # Runtime scope (state, param, locals, event)
    index.js               # Public JS exports

  controllers/tailmix/
    definitions_controller.rb  # Serves /tailmix/definitions/:name.json (for JS hydration)
  helpers/tailmix/
    view_helper.rb

config/routes.rb           # Mounts the definitions route

examples/
  tabs.rb / tabs.html.arb  # Working example

spec/
  tailmix_spec.rb          # RSpec tests (mostly stubs at present)
  spec_helper.rb
```

## Key Architectural Concepts

### Compiled Definition (Hash)
The compiler (`JSONGenerator`) produces a plain Ruby Hash that is also serializable to JSON:
```ruby
{
  name: "MyComponent",
  states:      { "open" => false, "count" => 0 },
  types:       { "open" => :boolean, "count" => :integer },
  persistence: { "open" => { type: :local, key: "open" } },
  variants:    { "size" => { default: :md } },
  elements: [
    { name: "button", static: {}, rules: [[:on, "click", [[:set, [:state, "open"], true]]], …] }
  ],
  boot:     [],
  watchers: [[:watch, [:state, "query"], [[:fetch, …]]]]
}
```

### Rule / Expression Arrays (shared Ruby ↔ JS format)
Rules and expressions are encoded as arrays so they can be serialized to JSON and interpreted on both sides:
- `[:style, condition, true_effect, false_effect]`
- `[:match, subject, { "val" => effect }, default_effect]`
- `[:on, "click", instructions]`
- `[:watch, subject_expr, instructions]` — reactive watcher
- `[:fetch, url_expr, options, success_block]`
- `[:set, target, value]` — assignment instruction
- `[:toggle, target]` — boolean flip
- `[:dispatch, "event-name", detail_hash]` — CustomEvent cross-component
- `[:state, "name"]` — state variable reference
- `[:variant, "name"]` — variant reference (static, SSR only)
- `[:event, "value"]` — event variable reference
- `[:local, "response"]` — local variable reference
- `[:param, "id"]` — per-element param reference
- `[:eq, left, right]`, `[:and, left, right]`, etc. — operators

### State vs Variants
- **State** (`state :open, default: false`): mutable at runtime, managed by JS, can be persisted.
- **Variants** (`variant :size, default: :md`): static compile-time props, passed at SSR, no JS needed.
- `tailmix(size: :lg)` in the Facade splits kwargs: variant keys → `@variants`, others → `@state`.

### State Types
State types are inferred from default values (integer, float, boolean, json, string) and used by `PersistenceManager` to cast values when loading from storage.

## Development Commands

```bash
# Ruby
bundle install
bundle exec rspec           # Run tests
bundle exec rubocop         # Lint (rubocop-rails-omakase, double-quoted strings)

# JavaScript
npm install
npm run build               # Production bundle → app/assets/javascripts/tailmix/tailmix.bundle.js
npm run dev                 # Development bundle (with source maps, no minify)
npm run watch               # Watch mode
```

## Coding Conventions

- **Ruby:** `# frozen_string_literal: true` on every file. Double-quoted strings (RuboCop enforced). Ruby >= 3.1.
- **JavaScript:** ES2018 target, IIFE bundle exposed as `window.Tailmix`. No TypeScript.
- **No external Ruby runtime dependencies** (pure Ruby gem).
- `ENV["TAILMIX_DEBUG"] = "true"` is currently hard-coded in `lib/tailmix.rb` for development — emits build-time output.
- The Ruby interpreter (`lib/tailmix/interpreter/`) mirrors the JS interpreter for SSR / testing scenarios.

## Branches

- `main` — stable branch
- `v2` — active development branch (current)
