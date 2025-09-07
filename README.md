# Tailmix

**Tailmix** is a powerful, declarative engine for managing HTML attributes in Ruby UI components. It allows you to co-locate all presentational logic—including CSS classes, data attributes, and ARIA roles—directly within your component's code, creating truly self-contained and maintainable components.

[](https://badge.fury.io/rb/tailmix)
[](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml)

Inspired by modern frontend tools like CVA (Class Variance Authority), Tailmix brings a robust styling engine to your server-side components (built with Arbre, ViewComponent, Phlex, etc.).

## Key Features

* **Declarative DSL:** Describe your component's styles with an elegant and intuitive API.
* **Variants & Compound Variants:** Easily manage different component states (`size`, `color`, etc.) and their combinations.
* **Component Inheritance:** Create base components and extend them to avoid code duplication.
* **Zero Dependencies:** Pure Ruby, ready to work in any project.


## Installation

Add the gem to your Gemfile:

```bash
bundle add tailmix
```

Then, run the installer to set up the JavaScript assets (required for `action` and `Stimulus` integration):

```bash
bin/rails g tailmix:install
```

-----

## Usage

The core idea of Tailmix is to describe all variants of your component within a Ruby class.

### 1. Basic Example: The `Modal` Component

**Component Definition:**

```ruby
# app/components/modal_component.rb
class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    plugin :auto_focus, on: :open_button, delay: 100
    state :open, default: false, toggle: true

    element :container do
    end

    element :open_button do
      # We attach the `click` event to our auto-generated action.
      on :click, :toggle_open
    end

    element :base do
      dimension :open do
        variant true, "fixed inset-0 z-50 flex items-center justify-center visible opacity-100 transition-opacity"
        variant false, "invisible opacity-0"
      end
    end

    element :overlay do
      dimension :open do
        variant true, "fixed inset-0 bg-black/50"
        variant false, "hidden"
      end
      on :click, :toggle_open
    end

    element :panel, "relative bg-white rounded-lg shadow-xl" do
      dimension :open do
        variant true, "block"
        variant false, "hidden"
      end
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-500 rounded-full cursor-pointer" do
      on :click, :toggle_open
    end

    element :title, "text-lg font-semibold text-gray-900 p-4 border-b"
    element :body, "p-4 text-gray-900"
  end

  def initialize(open: false, id: nil)
    @ui = tailmix(open: open, id: id)
  end
end
```

**Usage in ERB:**
In ERB, use the `**` operator to pass the attributes.

```erb
<% ui = ModalComponent.new(open: false, id: :user_profile_modal).ui %>

<div <%= tag.attributes **ui.container.component %>>
  ...
</div>
```

**Usage in Arbre:**
Arbre was the primary inspiration for Tailmix. Integration is seamless and does not require the `**` operator.

```ruby
# _example_modal_component.arb
modal_component = ModalComponent.new(open: false, id: :user_profile_modal)
ui = modal_component.ui

button "Open Modal Outer", tailmix_trigger_for(:user_profile_modal, :toggle_open)

div ui.container.component do
  button "Open Modal", ui.open_button

  div ui.base do
    div ui.overlay

    div ui.panel do
      div ui.title do
        h3 "Modal Title"
        button ui.close_button do
          text_node "✖"
        end
      end

      div ui.body do
        para "This is the main content of the modal. It's powered by the new Tailmix Runtime!"
      end
    end
  end
end
```


## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).