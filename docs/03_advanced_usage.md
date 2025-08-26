# Advanced Usage

This guide covers more advanced features of Tailmix, including component inheritance and using the developer tools.

## Component Inheritance

One of the most powerful features of Tailmix is the ability to inherit and extend component definitions. This allows you to create a base set of components for your design system and then specialize them for specific use cases.

When a component class inherits from another, their `tailmix` definitions are intelligently merged:

* **Base Classes**: Are combined, with duplicates removed.
* **Dimensions & Variants**: Are merged. If a child defines a variant with the same name as a parent (e.g., `:sm`), the child's definition will completely **override** the parent's for that specific variant. New variants are added.
* **Compound Variants**: Are combined. Both parent and child compound variants will be applied.
* **Actions**: Are merged. If a child defines an action with the same name as a parent, the child's definition **overrides** the parent's.

### Example: BaseButton and DangerButton

Let's define a `BaseButtonComponent` and then a more specific `DangerButtonComponent` that inherits from it.

**1. The Base Component**

```ruby
# app/components/base_button_component.rb
class BaseButtonComponent
  include Tailmix
  attr_reader :ui

  def initialize(size: :md)
    @ui = tailmix(size: size)
  end

  tailmix do
    element :button, "font-semibold border rounded" do
      dimension :size, default: :md do
        variant :sm, "px-2.5 py-1.5 text-xs"
        variant :md, "px-3 py-2 text-sm"
      end
    end
  end
end
```

**2. The Inherited Component**

The DangerButtonComponent inherits from BaseButtonComponent and only specifies what's different.

```ruby
# app/components/danger_button_component.rb
class DangerButtonComponent < BaseButtonComponent
  tailmix do
    # This adds to the parent's base classes
    element :button, "bg-red-500 text-white border-transparent hover:bg-red-600" do
      # This adds a new variant to the :size dimension
      dimension :size do
        variant :lg, "px-4 py-2 text-base"
      end
    end
  end
end
```

**Resulting Definition for `DangerButtonComponent`:**

The `:button` element will have the combined base classes: `"font-semibold border rounded bg-red-500 ..."`.

The `:size` dimension will now have three variants available: `:sm`, `:md` (from the parent), and `:lg` (from the child).

### Developer Tools

Tailmix includes a set of developer tools available via the `.dev` class method on your component.

`.dev.docs`

Prints a comprehensive summary of the component's definition, including its signature, dimensions, variants, compound variants, and actions. This is invaluable for understanding a component's API at a glance.

```ruby
puts DangerButtonComponent.dev.docs
```

`.dev.stimulus.scaffold`


Analyzes the component's `stimulus` definitions and generates a boilerplate Stimulus controller in your console, complete with all targets, values, and action methods.

```ruby
puts MyModalComponent.dev.stimulus.scaffold
```

