# tailmix

[![Gem Version](https://badge.fury.io/rb/tailmix.svg)](https://badge.fury.io/rb/tailmix)
[![Build Status](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml/badge.svg)](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml)

**Tailmix** is a powerful, declarative, and interactive class manager for building maintainable UI components in Ruby. It's designed to work seamlessly with utility-first CSS frameworks like **Tailwind CSS**, allowing you to co-locate your style logic with your component's code in a clean, structured, and highly reusable way.

Inspired by modern frontend tools like CVA (Class Variance Authority), `tailmix` brings a robust styling engine to your server-side components (like those built with Arbre, ViewComponent, or Phlex).

## Philosophy

* **Co-location & Isolation:** Define all style variants for a component directly within its class. No more hunting for styles in separate files. Each component is fully self-contained.
* **Declarative First:** A beautiful DSL to *declare* your component's visual appearance based on variants like `state`, `size`, etc.
* **Imperative Power:** A rich runtime API to dynamically and imperatively `add`, `remove`, or `toggle` classes, perfect for server-side updates via Hotwire/Turbo.
* **Framework-Agnostic:** Written in pure Ruby with zero dependencies, ready to be used in any project.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tailmix'
```

And then execute: `$ bundle install`

Or install it yourself as: `$ gem install tailmix`

## The DSL: A Detailed Breakdown

You define a component's style "schema" using the `tailmix` DSL within your class.

* `element :name, "base classes" do ... end`: Defines a "part" of your component. Every component has at least one element.
* `dimension :name do ... end` (e.g., `state do`, `size do`): Defines a variant "dimension".
* `option :name, "classes", default: true`: Defines a specific option within a dimension and its corresponding CSS classes. One option per dimension can be marked as the default.

### Full Example of the DSL

```ruby
class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    element :base, "fixed inset-0 z-50 flex items-center justify-center" do
      dimension :open, default: true do
        option true, "visible opacity-100"
        option false, "invisible opacity-0"
      end
      stimulus.controller("modal")
    end

    element :overlay, "fixed inset-0 bg-black/50 transition-opacity" do
      stimulus.context("modal").action("click->modal#close")
    end

    element :panel, "relative bg-white rounded-lg shadow-xl transition-transform transform" do
      dimension :size, default: :md do
        option :sm, "w-full max-w-sm p-4"
        option :md, "w-full max-w-md p-6"
        option :lg, "w-full max-w-lg p-8"
      end
      stimulus.context("modal").target("panel")
    end

    element :title, "text-lg font-semibold text-gray-900"
    element :body, "mt-2 text-sm text-gray-600"
    element :close_button, "absolute top-2 right-2 p-1 text-gray-400 rounded-full hover:bg-gray-100 hover:text-gray-600" do
      stimulus.context("modal").action("click->modal#close")
    end

    element :footer, "mt-4 pt-4 border-t flex justify-end"
    element :confirm_button, "relative inline-flex items-center px-4 py-2 bg-blue-600 text-white font-semibold rounded-md hover:bg-blue-700" do
      stimulus.controller("form-submission")
              .action("click->form-submission#submit")
              .action_payload(:enter_pending_state, as: :pending_data)
    end

    element :spinner, "absolute inset-0 flex items-center justify-center hidden"

    action :lock, method: :add do
      element :close_button do
        classes "hidden"
      end
      element :panel do
        data locked: true, reason: "processing"
      end
    end

    action :enter_pending_state, method: :add do
      element :confirm_button do
        classes "opacity-75 cursor-not-allowed"
      end
      element :spinner do
        classes "flex"
      end
    end
  end

  def initialize(size: :md, open: false)
    @ui = tailmix(size: size, open: open)
  end

  def lock!
    @ui.action(:lock).apply!
  end
end
```

```ruby
modal = ModalComponent.new(size: :lg, open: true)

# 
ui = modal.ui

# actions:
modal.lock!
# or
ui.action(:lock).apply!

# operations:
ui.panel.add("hidden")

ui.overlay.toggle("hidden")
# or
ui.overlay.classes.toggle("hidden")
```

```ruby
# Arbre view: _modal_example.arb

div ui.base do
  div ui.overlay

  div ui.panel do
    button ui.close_button do
      span "Close"
    end

    h3 ui.title do
      "Payment Successful"
    end

    div ui.body do
      "Your payment has been successfully submitted. We’ve sent you an email with all of the details of your order."
    end

    div ui.footer do
      button ui.confirm_button do
        span "Confirm Purchase"
        div ui.spinner do
          span "Loading..."
        end
      end
    end
  end
end
```

## Usage

### 1. Initialization

Inside your component, call the `tailmix` helper to create an interactive style manager. You can pass initial variants to it.

... (more to come)

### 3. The Bridge to JavaScript (Stimulus)

While `tailmix` is a server-side library, it enables clean integration with JavaScript controllers like Stimulus by providing the "source of truth" for classes.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/alexander-s-f/tailmix](https://github.com/alexander-s-f/tailmix).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).