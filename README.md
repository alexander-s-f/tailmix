# Tailmix

**Tailmix** is a declarative, state-driven engine for managing HTML attributes (CSS classes, data, ARIA) in Ruby UI components. Write your component logic once in Ruby — it runs on the server for SSR and hydrates in the browser for interactive behaviour.

[![Gem Version](https://badge.fury.io/rb/tailmix.svg)](https://badge.fury.io/rb/tailmix)
[![CI](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml/badge.svg)](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml)

---

## Why Tailmix?

Building interactive Ruby UI components (Arbre, ViewComponent, Phlex) usually means one of two things: a tangle of conditionals in the template, or a separate Stimulus controller per component. Tailmix offers a third path — a single declarative definition that handles both.

```ruby
tailmix do
  state :open, default: false

  element :panel do
    style condition: state.open do
      classes "block"
      aria expanded: true
      otherwise do
        classes "hidden"
        aria expanded: false
      end
    end
  end

  element :toggle_btn do
    on :click do
      toggle state.open
    end
  end
end
```

That's it. No Stimulus controller. No JS file. The same definition drives server-rendered HTML and browser interactivity.

---

## Features

- **Declarative DSL** — co-locate all presentational logic with your component class
- **State & Variants** — mutable runtime state (JS-driven) + static compile-time variants (SSR-only)
- **`style/otherwise`** — conditional attribute blocks with an explicit else branch
- **`match/on`** — pattern-match a state value to a set of attribute effects
- **`on :event`** — event handlers compiled to an instruction set (no hand-written JS)
- **`toggle` / `set` / `dispatch`** — built-in instructions; `dispatch` fires CustomEvents for cross-component communication
- **`boot {}`** — runs instructions once on JS component init (e.g. fetch initial data)
- **`watch state.x {}`** — reactive side-effects triggered when state changes
- **Persistence** — opt-in LocalStorage / SessionStorage per state key
- **Isomorphic** — Ruby SSR interpreter mirrors the JS runtime; test everything in RSpec
- **Zero runtime Ruby dependencies**

---

## Installation

```bash
bundle add tailmix
```

For JavaScript hydration, install the asset:

```bash
bin/rails g tailmix:install
```

---

## Quick start

### 1. Define the component

```ruby
# app/components/disclosure_component.rb
class DisclosureComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :open, default: false

    element :root do
      on :keydown do
        # Escape key closes
      end
    end

    element :trigger, "flex w-full items-center justify-between py-4 font-medium" do
      on :click do
        toggle state.open
      end
      aria expanded: state.open
    end

    element :panel do
      style condition: state.open do
        classes "block pb-4"
        otherwise do
          classes "hidden"
        end
      end
    end

    element :icon, "transition-transform duration-200" do
      style condition: state.open do
        classes "rotate-180"
      end
    end
  end

  def initialize(open: false)
    @ui = tailmix(open: open)
  end
end
```

### 2. Use in Arbre

```ruby
disclosure = DisclosureComponent.new
ui = disclosure.ui

div ui.root do
  button ui.trigger do
    span "Is Tailmix production-ready?"
    span ui.icon do
      # chevron SVG
    end
  end
  div ui.panel do
    para "Yes! The Ruby SSR path is stable and the JS runtime is actively developed."
  end
end
```

### 3. Use in ERB / ViewComponent

```erb
<% ui = DisclosureComponent.new.ui %>

<div <%= tag.attributes(**ui.root) %>>
  <button <%= tag.attributes(**ui.trigger) %>>
    Is Tailmix production-ready?
  </button>
  <div <%= tag.attributes(**ui.panel) %>>
    Yes! Absolutely.
  </div>
</div>
```

---

## DSL Reference

### State

Mutable values managed by the JS runtime. Types are inferred from the default value.

```ruby
state :open,    default: false              # boolean
state :count,   default: 0                  # integer
state :query,   default: ""                 # string
state :data,    default: nil, type: :json   # JSON blob

# Persist across page loads
state :theme,   default: "light", persist: :local    # localStorage
state :sidebar, default: true,   persist: :session   # sessionStorage
```

### Variants

Static compile-time props. Resolved at SSR, invisible to JavaScript.

```ruby
variant :size,  default: :md   # :sm | :md | :lg
variant :color, default: :blue
```

Pass variants when building the facade:

```ruby
@ui = tailmix(size: :lg, color: :green)
```

### Elements

```ruby
element :name, "static-classes" do
  # rules ...
end
```

Pass per-element params at render time:

```ruby
# Definition
element :tab do
  on :click do
    set state.active, param.id
  end
end

# Usage
ui.tab(id: "profile")
```

### style

```ruby
style condition: state.open do
  classes "block"
  aria expanded: true
  data foo: "bar"
  otherwise do
    classes "hidden"
    aria expanded: false
  end
end
```

### match

Pattern-match a state value to attribute sets:

```ruby
match state.size do
  on "sm", "text-sm px-2 py-1"
  on "lg", "text-lg px-6 py-3"
  default    "text-base px-4 py-2"
end
```

### on (event handlers)

```ruby
on :click do
  set   state.active, param.id     # assign value
  toggle state.open                # flip boolean
  dispatch "tab:changed", detail: { id: param.id }   # CustomEvent
  log "clicked"                    # console.log in browser
end
```

### fetch

```ruby
on :click do
  fetch "/api/items" do |response|
    set state.items, response
  end
end

# With query params and method
fetch "/api/search", method: :post, query: { q: state.query } do |response|
  set state.results, response
end
```

### boot

Runs once after JS component initialisation:

```ruby
boot do
  fetch "/api/initial-data" do |response|
    set state.data, response
  end
end
```

### watch

Reactive side-effects. Fires when the watched expression changes:

```ruby
watch state.query do
  fetch "/api/search", query: { q: state.query } do |response|
    set state.results, response
  end
end
```

---

## Examples

See the [`examples/`](examples/) directory for complete, working components:

| Example | Concepts |
|---------|----------|
| [`tabs.rb`](examples/tabs.rb) | `state`, `set`, `style`, `param` |
| [`modal.rb`](examples/modal.rb) | `toggle`, `dispatch`, `style/otherwise` |
| [`accordion.rb`](examples/accordion.rb) | `match`, `toggle`, multiple elements |
| [`live_search.rb`](examples/live_search.rb) | `watch`, `fetch`, debounce pattern |

---

## How it works

```
Ruby DSL
  └─ ComponentParser / ElementParser / ActionParser
       └─ AST (nodes.rb)
            └─ JSONGenerator (compiler)
                 └─ Definition Hash (JSON-serializable)
                      ├─ FacadeBuilder → Facade class (Ruby SSR)
                      └─ JS runtime (component.js) ← hydrates from JSON definition
```

The compiled definition is a plain Ruby Hash (also valid JSON). Both the Ruby interpreter and the JS runtime consume the same format, so server-rendered and client-rendered components behave identically.

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/alexander-s-f/tailmix).

## License

MIT — see [LICENSE](LICENSE).
