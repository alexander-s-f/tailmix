# Tailmix — AGENTS.md

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

---

## Component Development Guide (AI Agent Handbook)

This guide provides definitive rules, patterns, and architectural principles for AI agents developing new declarative, interactive components in **Tailmix UI**.

### 1. The Twin-Layer Architecture
Every interactive component in Tailmix UI has two parts:
1.  **The State Definition (CVA Logic):** A Ruby class (suffix `State`) that encapsulates variants, reactive states, DOM elements, and declarative event/transition rules.
    ```ruby
    class ModalState
      include Tailmix
      tailmix do
        state :open, default: false
        element :backdrop do
          on :click do
            set state.open, false
          end
        end
      end
    end
    ```
2.  **The Arbre Component (DOM Generation):** A subclass of `BaseComponent` that renders the HTML structure and hooks up CVA classes and attributes.
    ```ruby
    class Modal < BaseComponent
      def build(options = {})
        @modal_ui = ModalState.new.ui
        super(@modal_ui.backdrop(options)) # Set CVA root element classes
      end
    end
    ```

### 2. Crucial Arbre Scoping & Collision Resolution
In Arbre, tag builder helper methods (like `div`, `span`, `btn`, `modal`) are registered on the builder context. By default, Arbre executes a component's block *after* the `build` method returns, evaluating it with `self` as the parent `Arbre::Context`.

#### The HTML5 Tag Collision Problem
If you name a nested custom builder method after a standard HTML5 element (e.g., `menu` or `content`), **Arbre will intercept it** because standard HTML5 tag methods are defined on `Arbre::Context`. The context will directly call the standard HTML5 tag builder rather than delegating it to your component, resulting in a `NoMethodError` or broken layout when you invoke component-specific methods (like `item`) inside it.

#### The Safe Scoping Resolution
To bypass this collision and guarantee that `self` inside a component block refers to the component instance (so it can find custom methods like `menu`, `trigger`, or `close_button`), **you must define a custom tag builder helper on `Arbre::Element::BuilderMethods`** instead of relying on the default `builder_method :name` macro:

```ruby
module Arbre
  class Element
    module BuilderMethods
      def my_component(*args, &block)
        # 1. Build the tag (runs tag.build without the block)
        tag = build_tag ::TailmixUi::Components::MyComponent, *args
        
        # 2. Evaluate the block inside the component tag context manually
        if block
          with_current_arbre_element tag do
            tag.instance_eval(&block)
          end
        end
        
        # 3. Add to the active DOM parent and return
        current_arbre_element.add_child(tag)
        tag
      end
    end
  end
end
```

### 3. Preserving Element Attribute Identification
The Tailmix JavaScript runtime binds browser event listeners by looking up element definitions from `data-tailmix-element="..."` in the component's compiled JSON manifest.

> [!WARNING]
> **Component Attribute Overrides:** If you nest another Arbre component inside your trigger (e.g., rendering a custom `btn` inside a `trigger` block), the nested component's own CVA builder (like `btn(...)`) will override the `data-tailmix-element` attribute to its own identifier (e.g., `data-tailmix-element="btn"`). This prevents the JS runtime from identifying the trigger element.

**Rule:** For nested action elements (such as `trigger`, `close_btn`, or `backdrop`), **always render standard HTML tags** (like `button` or `div`) styled via CVA classes, rather than using custom sub-components. This preserves the `data-tailmix-element="trigger"` identifier intact.

```ruby
def trigger(label, options = {})
  # CORRECT: standard HTML button preserves trigger element identification
  button @dropdown_ui.trigger(options) do
    span label
  end
end
```

### 4. Explicit Hydration Rule
A component cannot toggle states or bind events in the browser unless it is successfully hydrated. The client-side JS runtime discovers components by query-selecting `[data-tailmix-component]`.

**Rule:** Every interactive layout component **must** explicitly call `set_attribute` inside its `build` method to define the CVA State class and initial state JSON on the root container element:

```ruby
def build(options = {})
  # ... CVA setup ...
  super(@my_ui.root(options))
  
  # Crucial hydration hooks!
  set_attribute "data-tailmix-component", MyState.name
  set_attribute "data-tailmix-state", @my_ui.state_json
end
```
Without these attributes, the browser runtime will ignore the element completely.

