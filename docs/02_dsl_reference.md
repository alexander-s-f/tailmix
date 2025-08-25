
# DSL Reference

The Tailmix DSL is designed to be declarative, expressive, and intuitive. All definitions are placed within a `tailmix do ... end` block inside your component class.

## `element`

The `element` method is the top-level keyword used to define a logical part or section of your component.

### Syntax

```ruby
element :name, "optional base classes" do
  # ... further definitions for this element
end
```

* **`:name` (Symbol)**: A unique name for the element, like `:wrapper`, `:title`, or `:close_button`. This name is used to access the element's attributes from the `ui` object (e.g., `ui.wrapper`).
* **`"base classes"` (String, optional)**: A space-separated string of CSS classes that will always be applied to this element, regardless of any variants.
* **`do ... end` block**: This is where you define the element's variants using `dimension`.

### Example

```ruby
tailmix do
  # An element with no base classes
  element :wrapper do
    # ...
  end

  # An element with base classes
  element :title, "text-lg font-bold text-gray-900"
end
```

-----

## `dimension`

A `dimension` defines an axis of variation for an element. It represents a property of the component that can change and affect its styling, such as `size`, `color`, or `state`. It must be defined inside an `element` block.

### Syntax

```ruby
dimension :name, default: :value do
  # ... variant definitions
end
```

* **`:name` (Symbol)**: The name of the dimension, like `:size` or `:intent`.
* **`default: :value` (optional)**: The default value for this dimension if none is provided when the component is initialized.

### Example

```ruby
element :button, "rounded-lg" do
  dimension :size, default: :md do
    # ... variants for :sm, :md, :lg
  end

  dimension :intent, default: :primary do
    # ... variants for :primary, :secondary, :danger
  end
end
```

-----

## `variant`

The `variant` method defines the specific styles that should be applied when a `dimension` has a certain value. It must be defined inside a `dimension` block.

### Syntax

There are two forms for defining a variant:

**1. Simple (inline classes)**

```ruby
variant :name, "classes to apply"
```

**2. Advanced (with a block)**

```ruby
variant :name, "optional base classes for this variant" do
  classes "...", group: :optional_label
  data key: "value"
  aria key: "value"
end
```

* **`:name` (Symbol|Boolean|String)**: The value of the dimension this variant corresponds to (e.g., `:md`, `true`).
* **`"classes"` (String)**: A space-separated string of CSS classes.
* **`do ... end` block**: For more complex definitions:
    * **`classes`**: Can be called multiple times to logically group classes. The optional `group:` option is for documentation purposes.
    * **`data`**: A hash to define `data-*` attributes.
    * **`aria`**: A hash to define `aria-*` attributes for accessibility.

### Example

```ruby
dimension :size, default: :md do
  # Simple variant
  variant :sm, "px-2 py-1 text-sm"

  # Advanced variant with a block
  variant :md, "px-4 py-2" do
    classes "text-base font-semibold", group: :typography
    data size: "medium"
    aria pressed: "false"
  end
end
```

-----

## `compound_variant`

A `compound_variant` allows you to define styles that apply only when a specific **combination** of dimensions is active. This is crucial for handling interdependencies in a design system. It must be defined inside an `element` block.

### Syntax

```ruby
compound_variant on: { dimension1: :value, dimension2: :value } do
  # ... modifications (classes, data, aria)
end
```

* **`on: { ... }` (Hash)**: A hash specifying the exact conditions under which this rule should be applied.
* **`do ... end` block**: The modifications to apply. It uses the same `classes`, `data`, and `aria` methods as the `variant` block.

### Example

This example makes an "outline" button's text and border color match its intent.

```ruby
element :button do
  dimension :intent, default: :primary do
    variant :primary, "bg-blue-500 text-white border-blue-500"
    variant :danger, "bg-red-500 text-white border-red-500"
  end

  dimension :look, default: :fill do
    variant :outline, "bg-transparent"
  end

  # Apply these classes ONLY when look is :outline AND intent is :primary
  compound_variant on: { look: :outline, intent: :primary } do
    classes "text-blue-500"
  end

  # Apply these classes ONLY when look is :outline AND intent is :danger
  compound_variant on: { look: :outline, intent: :danger } do
    classes "text-red-500"
  end
end
```

-----

## `action`

The `action` method defines a named set of imperative UI mutations that can be triggered at runtime. This is the core of the client-side bridge for optimistic updates with Hotwire/Turbo. It is defined at the top level of the `tailmix` block.

### Syntax

```ruby
action :name, method: :add | :remove | :toggle do
  element :element_to_modify do
    classes "..."
    data key: "value"
  end
end
```

* **`:name` (Symbol)**: A unique name for the action, like `:show_spinner` or `:disable_form`.
* **`method:`**: The default operation for all modifications within the block (`:add`, `:remove`, or `:toggle`).
* **`element :name do ... end`**: Specifies which element the following modifications apply to.

### Example

```ruby
action :show_pending_state, method: :add do
  element :submit_button do
    classes "opacity-50 cursor-not-allowed"
    data pending: true
  end

  element :spinner do
    # You can override the default method for a specific modification
    classes "hidden", method: :remove
  end
end
```

-----

## `stimulus`

The `stimulus` DSL provides helpers for declaratively adding Stimulus `data-*` attributes. It is available inside any `element` block. The DSL is chainable and context-aware.

### Setting the Context

Most helpers require a controller context to be set first. You can do this in two ways:

* **`.controller("name")`**: This is the primary method. It both adds a `data-controller="name"` attribute and sets the context for subsequent chained calls.
* **`.context("name")`**: This method only sets the context for subsequent calls without adding a new `data-controller` attribute. This is useful when you want to add targets or actions to an element that is inside the scope of a controller defined on a parent element.

### Helpers (Context-Aware)

These methods must be called after `.controller()` or `.context()`.

#### **`.target("name")`**

Adds a target for the current controller context.

* **Syntax**: `.target("myTarget")`
* **Result**: `data-[controller-name]-target="myTarget"`

#### **`.action(event, method)` or `.action("specifier")`**

Adds an action for the current controller context. It has multiple forms for flexibility.

* **Syntax 1 (Tuple)**: `.action(:click, :open)` -\> `data-action="click->[controller-name]#open"`
* **Syntax 2 (Hash)**: `.action(click: :open, mouseenter: :highlight)` -\> `data-action="click->[controller-name]#open mouseenter->[controller-name]#highlight"`
* **Syntax 3 (Raw String)**: `.action("click->other-controller#doSomething")`

#### **`.value(:name, ...)`**

Adds a value for the current controller context. It can be a literal value, or it can be resolved dynamically from a method or a proc.

* **Syntax**:
    * `.value(:my_value, value: "some-string")`
    * `.value(:user_id, method: :current_user_id)`
    * `.value(:timestamp, call: -> { Time.now.to_i })`
* **Result**: `data-[controller-name]-my-value-value="..."`

#### **`.action_payload(:action, as: :value_name)`**

A powerful helper that serializes a Tailmix `action` definition into a Stimulus value, making it available on the client-side.

* **Syntax**: `.action_payload(:disable_form, as: :disable_data)`
* **Result**: `data-[controller-name]-disable-data-value="{...json...}"`

### Example

```ruby
element :confirm_button, "px-4 py-2" do
  stimulus
    .controller("modal")                                # -> data-controller="modal"
    .action(:click, :open)                               # -> data-action="click->modal#open"
    .target("panel")                                     # -> data-modal-target="panel"
    .value(:url, value: "/items/1")                      # -> data-modal-url-value="/items/1"
    .action_payload(:toggle, as: :toggle_data)           # -> data-modal-toggle-data-value="{...}"
end

element :overlay do
  # Assume `modal` controller is on a parent element
  stimulus
    .context("modal")
    .action(:click, :close)                              # -> data-action="click->modal#close"
end
```

-----
