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
* `dimension_name do ... end` (e.g., `state do`, `size do`): Defines a variant "dimension". The name can be anything you choose.
* `option :name, "classes", default: true`: Defines a specific option within a dimension and its corresponding CSS classes. One option per dimension can be marked as the default.

### Full Example of the DSL

```ruby
class MyButtonComponent
  include Tailmix

  tailmix do
    # Define the main element and its base classes
    element :button, "inline-flex items-center font-medium rounded-md" do
      # Define the 'size' dimension
      size do
        option :sm, "px-2.5 py-1.5 text-xs", default: true
        option :md, "px-3 py-2 text-sm"
        option :lg, "px-4 py-2 text-base"
      end

      # Define the 'intent' dimension
      intent do
        option :primary, "bg-blue-600 text-white hover:bg-blue-700", default: true
        option :secondary, "bg-gray-200 text-gray-800 hover:bg-gray-300"
        option :danger, "bg-red-600 text-white hover:bg-red-700"
      end
    end

    # Define another element, like an icon
    element :icon, "inline-block" do
      size do
        option :sm, "h-4 w-4"
        option :md, "h-5 w-5", default: true
        option :lg, "h-6 w-6"
      end
    end
  end
  # ...
end
```

## Usage

### 1. Initialization

Inside your component, call the `tailmix` helper to create an interactive style manager. You can pass initial variants to it.

```ruby
class MyButtonComponent
  # ... (tailmix DSL from above)

  attr_reader :classes

  def initialize(intent: :primary, size: :md)
    # The `tailmix` helper creates and returns the manager object
    @classes = tailmix(intent: intent, size: size)
  end
  
  def render
    # The manager's methods map to your elements.
    # Ruby's `to_s` is called implicitly when rendering.
    "<button class='#{@classes.button}'>
       <span class='#{@classes.icon}'></span>
       Click me
     </button>"
  end
end

# Renders a medium primary button by default
button = MyButtonComponent.new
button.render

# Renders a small danger button
button = MyButtonComponent.new(intent: :danger, size: :sm)
button.render
```

### 2. Dynamic & Imperative Usage

This is where `tailmix` truly shines. The `@classes` object is a live manager that you can modify. This is perfect for server-side re-rendering with Hotwire/Turbo.

```ruby
class MyButtonComponent
  # ...

  # A method that might be called during a Turbo Stream update
  def set_loading_state!
    # The `combine` method updates the declarative state
    @classes.combine(intent: :secondary)
    
    # The imperative API allows for fine-grained control
    @classes.button.add("cursor-wait opacity-75")
    @classes.icon.add("animate-spin")
  end

  def remove_loading_state!
    @classes.combine(intent: :primary) # Revert to original intent
    @classes.button.remove("cursor-wait opacity-75")
    @classes.icon.remove("animate-spin")
  end
end

button = MyButtonComponent.new(intent: :primary)
button.set_loading_state!
button.render # Renders the button in a loading state

button.remove_loading_state!
button.render # Renders the button back in its primary state
```

### 3. The Bridge to JavaScript (Stimulus)

While `tailmix` is a server-side library, it enables clean integration with JavaScript controllers like Stimulus by providing the "source of truth" for classes. You can create a helper to export variants to `data-` attributes, keeping your JS free of hardcoded style strings.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/alexander-s-f/tailmix](https://github.com/alexander-s-f/tailmix).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).