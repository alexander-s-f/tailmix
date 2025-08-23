# Tailmix

**Tailmix** is a powerful, declarative, and interactive CSS class manager for building maintainable UI components in Ruby. It's designed to work seamlessly with utility-first CSS frameworks like **Tailwind CSS**, allowing you to co-locate your style logic with your component's code—in a clean, structured, and highly reusable way.

[![Gem Version](https://badge.fury.io/rb/tailmix.svg)](https://badge.fury.io/rb/tailmix)
[![Build Status](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml/badge.svg)](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml)

Inspired by modern frontend tools like CVA (Class Variance Authority), Tailmix brings a robust styling engine to your server-side components (built with Arbre, ViewComponent, Phlex, etc.).

## Philosophy

* **Co-location & Isolation:** Define all style variants for a component directly within its class. No more hunting for styles in separate files. Each component is fully self-contained.
* **Declarative First:** A beautiful DSL to declaratively describe your component's appearance based on variants like state, size, etc.
* **Imperative Power:** A rich runtime API to dynamically add, remove, or toggle classes, perfect for server-side updates via Hotwire/Turbo.
* **Framework-Agnostic:** Written in pure Ruby with zero dependencies, ready to be used in any project.

## Installation

Add the gem to your Gemfile:

```ruby
gem 'tailmix'
````

Or install it from the command line:

```bash
bundle add tailmix
```

Next, run the installer to set up the JavaScript assets:

```bash
bin/rails g tailmix:install
```

## Core Concepts

You define your component's appearance using a simple `tailmix do ... end` DSL inside your class.

- `element :name, "base classes"`: Defines a logical part of your component (e.g., `:wrapper`, `:panel`, `:icon`).
- `dimension :name, default: :value`: Defines a variant or "dimension" (e.g., `size` or `color`).
- `option :value, "classes"`: Defines the classes for a specific variant option.
- `action :name, method: :add | :toggle | :remove`: Defines a named set of UI mutations that can be applied on the server (`.apply!`) or passed to the client (`action_payload`).
- `stimulus`: A powerful nested DSL for declaratively describing Stimulus `data-*` attributes.

## Usage Example

Let's build a complex `ModalComponent` from scratch.
#### 1. Define the Component (`app/components/modal_component.rb`)

This is a plain Ruby class that contains all the style and behavior logic.

```ruby
class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    element :base, "fixed inset-0 z-50 flex items-center justify-center" do
      dimension :open, default: false do
        option true, "visible opacity-100"
        option false, "invisible opacity-0"
      end
      stimulus.controller("modal")
    end

    element :overlay, "fixed inset-0 bg-black/50 transition-opacity" do
      stimulus.context("modal").action(click: :close)
    end

    element :panel, "relative bg-white rounded-lg shadow-xl" do
      dimension :size, default: :md do
        option :sm, "w-full max-w-sm p-4"
        option :md, "w-full max-w-md p-6"
      end
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-400" do
      stimulus.context("modal").action(click: :close)
    end

    element :confirm_button, "px-4 py-2 bg-blue-600 text-white rounded-md" do
      stimulus.controller("form-submission")
              .action(:click, :show_pending_state)
              .action_payload(:show_pending_state, as: :pending_data)
    end
    
    action :show_pending_state, method: :add do
      element :confirm_button do
        classes "is-loading"
        data pending: true
      end
    end
  end

  def initialize(open: false, size: :md)
    @ui = tailmix(open: open, size: size)
  end
end
```

#### 2. Use in a View (Arbre, ERB, etc.)

Thanks to Tailmix's design, you can pass `ui` objects directly to many rendering helpers.

##### Arbre

The API is seamless. The `ui` object behaves like an attributes hash automatically.

Ruby

```ruby
# app/views/components/my_modal.arb
# 1. Instantiate the component with the desired variants
modal = ModalComponent.new(open: true, size: :sm)

# 2. Render by passing the ui objects directly to Arbre's tag helpers
div modal.ui.base do
  div modal.ui.overlay

  div modal.ui.panel do
    # ... your content ...
    button modal.ui.confirm_button, "Confirm"
  end
end
```

##### ERB / Rails Tag Helpers

In ERB, the idiomatic way to pass a hash-like object as attributes is with the double splat (`**`) operator.

Фрагмент кода

```
<%# app/views/pages/home.html.erb %>
<% modal = ModalComponent.new(open: true, size: :sm) %>

<%= tag.div **modal.ui.base do %>
  <%= tag.div **modal.ui.overlay %>

  <%= tag.div **modal.ui.panel do %>
    <%# ... your content ... %>
    <%= tag.button "Confirm", **modal.ui.confirm_button %>
  <% end %>
<% end %>
```

#### 3. Bring it to Life with Stimulus

The `action_payload` helper makes it easy to connect server-side definitions with client-side behavior.

JavaScript

```js
// app/javascript/controllers/form_submission_controller.js
import { Controller } from "@hotwired/stimulus"
import Tailmix from "tailmix"

export default class extends Controller {
  static values = { pendingData: Object }

  showPendingState(event) {
    event.preventDefault()
    
    // Instantly apply UI changes from the payload
    Tailmix.run({
      config: this.pendingDataValue,
      controller: this
    });

    // ... then submit the form or send an AJAX request
  }
}
```

## Developer Tools

Tailmix comes with built-in introspection tools to improve your development experience. Access them via the `.dev` namespace on your component class.

#### Component Documentation

Get a cheat sheet of all available `dimensions` and `actions` right in your console.

```ruby
puts ModalComponent.dev.docs
```

#### Stimulus Controller Generator

Tailmix can analyze your component and scaffold a perfect boilerplate Stimulus controller with all targets, values, and action methods.

```ruby
puts ModalComponent.dev.stimulus.scaffold("modal")
```

## Configuration

You can configure Tailmix by creating an initializer:

```ruby
# config/initializers/tailmix.rb
Tailmix.configure do |config|
  # The attribute used by the universal JS selector.
  config.element_selector_attribute = "data-tm-el"
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/alexander-s-f/tailmix](https://github.com/alexander-s-f/tailmix).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).