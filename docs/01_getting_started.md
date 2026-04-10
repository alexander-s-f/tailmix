# Getting Started with Tailmix

## What is Tailmix?

Tailmix is a declarative engine for HTML attributes in Ruby UI components. The key idea: you describe **what** your component looks like in each state, and Tailmix figures out which classes, data attributes, and ARIA properties to apply — both server-side (SSR) and in the browser.

Think of it as CVA (Class Variance Authority) for Ruby, but with a built-in JS runtime so interactive components don't need a separate Stimulus controller.

---

## Installation

### 1. Add the gem

```bash
bundle add tailmix
```

Or in your `Gemfile`:

```ruby
gem "tailmix"
```

### 2. Install JavaScript assets

```bash
bin/rails g tailmix:install
```

This adds `tailmix.bundle.js` to your asset pipeline. Components with event handlers will auto-hydrate when the page loads.

---

## Core concepts

### State vs Variants

Tailmix has two kinds of component data:

**State** — mutable, managed by the browser. Changes trigger DOM updates.

```ruby
state :open,  default: false   # starts closed, JS can toggle it
state :count, default: 0       # integer, tracked per-component
state :query, default: ""      # string, e.g. for live search
```

**Variants** — static, resolved at render time. Like props. No JS involved.

```ruby
variant :size,  default: :md   # :sm | :md | :lg — chosen by the caller
variant :color, default: :gray
```

Variants are great for things that don't change after the page loads (button size, colour theme, component type). State is for everything interactive.

### Elements

An element maps to a DOM node. The facade method returns an attribute hash you splat into your template helper.

```ruby
element :trigger, "base-classes" do
  # rules applied on top of base-classes
end
```

At render time:

```ruby
ui = tailmix(size: :lg)
ui.trigger          # => { class: "base-classes ...", "data-..." => "..." }
ui.trigger(id: "x") # passing per-element params
```

### Rules

Rules inside an element block describe **how attributes change** based on state. Three kinds:

| Rule | Purpose |
|------|---------|
| `style condition: expr` | Apply attributes when condition is true |
| `match state.x` | Pattern-match a value, apply the matching effect |
| `on :event` | Compile an event handler into an instruction set |

---

## Your first component: Badge

A badge with `size` and `color` variants — pure SSR, no JS needed.

```ruby
# app/components/badge_component.rb
class BadgeComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    variant :size,  default: :md
    variant :color, default: :gray

    element :root, "inline-flex items-center font-medium rounded-full" do
      match variant.size do
        on "sm", "px-2 py-0.5 text-xs"
        on "md", "px-2.5 py-1 text-sm"
        on "lg", "px-3 py-1.5 text-base"
      end

      match variant.color do
        on "gray",  "bg-gray-100 text-gray-700"
        on "blue",  "bg-blue-100 text-blue-700"
        on "green", "bg-green-100 text-green-700"
        on "red",   "bg-red-100 text-red-700"
      end
    end
  end

  def initialize(size: :md, color: :gray)
    @ui = tailmix(size: size, color: color)
  end
end
```

Usage in Arbre:

```ruby
badge = BadgeComponent.new(size: :sm, color: :green)

span badge.ui.root do
  text_node "Active"
end
```

Usage in ERB:

```erb
<% badge = BadgeComponent.new(color: :red) %>
<span <%= tag.attributes(**badge.ui.root) %>>Overdue</span>
```

---

## Adding interactivity: Toggle

Let's make a Disclosure (show/hide) component. It needs state that changes in the browser.

```ruby
# app/components/disclosure_component.rb
class DisclosureComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :open, default: false

    element :trigger, "flex w-full items-center justify-between py-3 font-medium text-left" do
      on :click do
        toggle state.open
      end
    end

    element :icon, "h-5 w-5 transition-transform duration-200" do
      style condition: state.open do
        classes "rotate-180"
      end
    end

    element :panel do
      style condition: state.open do
        classes "pb-4"
        aria expanded: true
        otherwise do
          classes "hidden"
          aria expanded: false
        end
      end
    end
  end

  def initialize(open: false)
    @ui = tailmix(open: open)
  end
end
```

The `toggle state.open` instruction compiles to `[:toggle, [:state, "open"]]` — a tiny data structure that the JS runtime executes when the button is clicked. No hand-written JavaScript.

---

## Responding to events: Tabs

Tabs show how to use `param` to pass data into event handlers.

```ruby
# app/components/tabs_component.rb
class TabsComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :active, default: "overview"

    element :tab, "px-4 py-2 text-sm font-medium cursor-pointer border-b-2 transition-colors" do
      on :click do
        set state.active, param.id
      end

      style condition: state.active == param.id do
        classes "border-blue-500 text-blue-600"
        aria selected: true
        otherwise do
          classes "border-transparent text-gray-500 hover:text-gray-700"
          aria selected: false
        end
      end
    end

    element :panel, "py-4" do
      style condition: state.active != param.id do
        classes "hidden"
      end
    end
  end

  def initialize(active: "overview")
    @ui = tailmix(active: active)
  end
end
```

Each tab and panel is rendered with its own `id` param:

```ruby
tabs = TabsComponent.new
ui   = tabs.ui

# Nav
div class: "border-b" do
  %w[overview details settings].each do |tab_id|
    button ui.tab(id: tab_id) do
      text_node tab_id.capitalize
    end
  end
end

# Panels
div ui.panel(id: "overview") do
  para "Overview content"
end
div ui.panel(id: "details") do
  para "Details content"
end
div ui.panel(id: "settings") do
  para "Settings content"
end
```

---

## Fetching data: Live Search

The `watch` DSL lets you react to state changes. Combine it with `fetch` for live search:

```ruby
# app/components/search_component.rb
class SearchComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    state :query,   default: ""
    state :results, default: [], type: :json
    state :loading, default: false

    element :input, "w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" do
      on :input do
        set state.query, event.value
      end
    end

    element :spinner do
      style condition: state.loading do
        classes "block animate-spin"
        otherwise do
          classes "hidden"
        end
      end
    end

    element :results_list do
      style condition: state.loading do
        classes "opacity-50 pointer-events-none"
      end
    end

    watch state.query do
      set state.loading, true
      fetch "/api/search", query: { q: state.query } do |response|
        set state.results, response
        set state.loading, false
      end
    end
  end

  def initialize
    @ui = tailmix
  end
end
```

---

## State persistence

Any state key can be persisted to localStorage or sessionStorage:

```ruby
state :sidebar_open, default: true,    persist: :local    # survives page reload
state :draft_text,   default: "",      persist: :session  # survives navigation, cleared on tab close
```

The JS `PersistenceManager` saves and restores these values automatically. Type casting is applied on load (boolean, integer, float, JSON).

---

## Cross-component communication

Use `dispatch` to fire a `CustomEvent` from one component and listen for it in another:

```ruby
# sender component
element :confirm_btn do
  on :click do
    dispatch "modal:close", detail: { saved: true }
  end
end
```

In the receiving component, listen via `on "modal:close"` (custom events bubble up the DOM):

```ruby
element :root do
  on "modal:close" do
    set state.open, false
    log "Modal closed, saved:", event.detail.saved
  end
end
```

---

## Next steps

- [`examples/`](../examples/) — complete component implementations
- [`docs/02_dsl_reference.md`](02_dsl_reference.md) — full DSL API reference
- [`docs/03_js_runtime.md`](03_js_runtime.md) — how the JavaScript hydration works
