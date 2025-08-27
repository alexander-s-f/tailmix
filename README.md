# Tailmix

**Tailmix** is a powerful, declarative engine for managing HTML attributes in Ruby UI components. It allows you to co-locate all presentational logic—including CSS classes, data attributes, and ARIA roles—directly within your component's code, creating truly self-contained and maintainable components.

[](https://badge.fury.io/rb/tailmix)
[](https://github.com/alexander-s-f/tailmix/actions/workflows/main.yml)

Inspired by modern frontend tools like CVA (Class Variance Authority), Tailmix brings a robust styling engine to your server-side components (built with Arbre, ViewComponent, Phlex, etc.).

## Key Features

* **Declarative DSL:** Describe your component's styles with an elegant and intuitive API.
* **Variants & Compound Variants:** Easily manage different component states (`size`, `color`, etc.) and their combinations.
* **Stimulus Bridge:** Seamlessly integrate with StimulusJS to create interactive components.
* **"Hot" UI Updates:** Enable optimistic UI updates with `action` and `action_payload` in tandem with Hotwire/Turbo.
* **Component Inheritance:** Create base components and extend them to avoid code duplication.
* **Developer Tools:** Get built-in documentation and code generators right in your console.
* **Zero Dependencies:** Pure Ruby, ready to work in any project.

-----

## Quick Links

* **[Full Documentation →](/docs)**
* **[DSL Reference](/docs/02_dsl_reference.md)**
* **[Cookbook (Recipes)](/docs/05_cookbook.md)**


-----

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

### 1. Basic Example: The `Badge` Component

Let's create a simple, flexible `Badge` that can have different colors.

**Component Definition:**

```ruby
# app/components/badge_component.rb
class BadgeComponent
  include Tailmix
  attr_reader :ui, :text

  def initialize(text, color: :gray)
    @ui = tailmix(color: color)
    @text = text
  end

  tailmix do
    element :badge, "inline-flex items-center px-2.5 py-0.5 text-xs font-medium rounded-full" do
      dimension :color, default: :gray do
        variant :gray,    "bg-gray-100 text-gray-800"
        variant :success, "bg-green-100 text-green-800"
        variant :danger,  "bg-red-100 text-red-800"
      end
    end
  end
end
```

**Usage in ERB:**
In ERB, use the `**` operator to pass the attributes.

```erb
<% badge = BadgeComponent.new("Active", color: :success) %>

<span <%= tag.attributes **badge.ui.badge %>>
  <%= badge.text %>
</span>
```

**Usage in Arbre:**
Arbre was the primary inspiration for Tailmix. Integration is seamless and does not require the `**` operator.

```ruby
# my_view.arb
badge = BadgeComponent.new("Active", color: :success)
ui = badge.ui

span ui.badge do
  text_node badge.text
end
```

### 2\. Adding Interactivity with Stimulus

Tailmix allows you to declaratively define Stimulus controllers. Let's build a component to copy text to the clipboard.

**Component Definition:**

```ruby
# app/components/clipboard_component.rb
class ClipboardComponent
  include Tailmix
  attr_reader :ui, :text_to_copy

  def initialize(text_to_copy)
    @ui = tailmix
    @text_to_copy = text_to_copy
  end

  tailmix do
    element :wrapper, "flex items-center space-x-2" do
      stimulus.controller("clipboard") # data-controller="clipboard"
    end

    element :source, "p-2 border rounded-md bg-gray-50" do
      stimulus.context("clipboard").target("source") # data-clipboard-target="source"
    end

    element :button, "px-3 py-2 text-sm font-medium text-white bg-blue-600 rounded-md" do
      stimulus.context("clipboard").action(:click, :copy) # data-action="click->clipboard#copy"
    end
  end
end
```

**Stimulus Controller:**
Generate a template with `puts ClipboardComponent.dev.stimulus.scaffold` and fill in the logic.

```javascript
// app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent)
    // Optionally: show a success notification
  }
}
```

Your component is now fully interactive, with its entire structure defined in a single Ruby file.

-----

## 3. Advanced Example: An Interactive Modal

Now let's see the full power of Tailmix by building a common UI pattern: a fully interactive modal component. This example combines multiple elements, shared variants, Stimulus integration, and a client-side action for optimistic updates.

Component Definition:
The `ModalComponent` definition is self-contained. It describes the structure, all possible states, and the interactive behavior of the modal.

```ruby
# app/components/modal_component.rb
class ModalComponent
  include Tailmix
  attr_reader :ui

  tailmix do
    # A container to hold the controller and its data
    element :container do
      stimulus.controller("modal")
              .action_payload(:toggle, as: :toggle_data)
              # dynamic values:
              .value(:user_id, method: :get_current_user_id)
              .value(:generated_at, call: -> { Time.now.iso8601 })
    end

    # The button that will trigger the modal
    element :open_button, "inline-flex text-white bg-blue-600 rounded-lg px-5 py-2.5 cursor-pointer" do
      stimulus.context("modal").action(:click, :toggle)
    end

    # The modal's backdrop and wrapper, controlled by the :open dimension
    element :base, "flex items-center justify-center" do
      dimension :open, default: false do
        variant true, "fixed inset-0 z-50 visible opacity-100 transition-opacity"
        variant false, "invisible opacity-0"
      end
    end

    element :overlay, "fixed inset-0 bg-black/50" do
      stimulus.context("modal").action(:click, :toggle)
    end

    # The main modal panel, with variants for both :open and :size
    element :panel, "w-full relative bg-white rounded-lg shadow-xl" do
      dimension :open, default: false do
        variant true, "block"
        variant false, "hidden"
      end
      dimension :size, default: :md do
        variant :sm, "max-w-sm p-4"
        variant :md, "max-w-md p-6"
      end
      stimulus.context("modal").target("panel")
    end

    element :close_button, "absolute top-2 right-2 p-1 text-gray-500 rounded-full cursor-pointer" do
      stimulus.context("modal").action(:click, :toggle)
    end

    # The action that will be executed on the client-side
    action :toggle, method: :toggle do
      element :base do
        classes "visible opacity-100"
        classes "invisible opacity-0"
      end
      element :overlay do
        classes "fixed inset-0 bg-black/50"
      end
      element :panel do
        classes "block"
        classes "hidden"
      end
    end
  end

  def initialize(size: :md, open: false)
    @ui = tailmix(size: size, open: open)
  end

  def get_current_user_id
    123
  end
end
```

**Stimulus Controller:**
This controller will handle the modal's open/close logic and use the `action_payload` to trigger the closing animation defined in Ruby.

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"
import Tailmix from "tailmix"

export default class extends Controller {
    static values = { toggleData: Object }

    toggle(event) {
        // Prevent default browser behavior, like form submissions
        if (event) event.preventDefault();

        // Run the UI mutations defined in our Ruby :toggle action
        Tailmix.run({
            config: this.toggleDataValue,
            controller: this
        });
    }
}
```

**View Usage (Arbre):**
The view code is clean and readable. We instantiate the component and render its elements. The action_payload is serialized to the container element, making it available to the Stimulus controller.

```ruby
# my_view.arb
modal = ModalComponent.new(size: :sm)
ui = modal.ui

div ui.container do
  button "Open Modal", ui.open_button

  div ui.base do
    div ui.overlay
    div ui.panel do
      button "Close", ui.close_button
      h3 "Payment Successful", ui.title

      div ui.body do
        "Your payment has been successfully submitted..."
      end
    end
  end
end
```

-----

## 3. Advanced Tailmix + Declarable: A Shopping Cart Item
Perfect with `Declarable` for a complex component with a declarative approach.

```ruby
class ShoppingCartItemComponent
  include Declarable
  include Tailmix

  # Declarable dsl
  declarable do
    state :unit_price, default: 0
    state :quantity, default: 1, validates: { inclusion: { in: 1..10 } }

    derive :total_price, from: [:unit_price, :quantity] do |price, qty|
      price * qty
    end

    derive :is_expensive, from: :total_price do |total|
      total > 1000
    end

    action :increment do |context|
      context.quantity += 1
    end
  end

  # Tailmix dsl
  tailmix do
    element :wrapper, "flex justify-between items-center p-4 border-b" do
      # We change the background reactively if the product is expensive!
      dimension :is_expensive, default: false do
        variant true, "bg-yellow-50"
        variant false, "bg-white"
      end
    end

    element :total_price_text, "font-bold"
  end

  attr_reader :context, :ui

  def initialize(price:, quantity: 1)
    # Init Declarable
    @context = initialize_declarable(unit_price: price, quantity: quantity)
    
    # Passing derived values from Declarable directly to Tailmix!
    @ui = tailmix(is_expensive: @context.is_expensive)
  end
end
```

-----

## Developer Tools

Use the `.dev` namespace to introspect your components right from the console.

* **`YourComponent.dev.docs`**: Displays full documentation for all variants and actions.
* **`YourComponent.dev.stimulus.scaffold`**: Generates a Stimulus controller template.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).