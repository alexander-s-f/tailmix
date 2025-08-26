# Getting Started with Tailmix

Welcome to Tailmix! This guide will walk you through installing the gem, setting up your project, and creating your first component.

## Philosophy

Tailmix is built on the idea of **co-location**. Instead of defining component styles in separate CSS, SCSS, or CSS-in-JS files, you define them directly within the Ruby class that represents your component. This creates self-contained, highly reusable, and easily maintainable UI components.

The core of Tailmix is a powerful and expressive **DSL (Domain-Specific Language)** that allows you to declaratively define how a component should look based on its properties or "variants".

## Installation

Getting started with Tailmix involves two simple steps: adding the gem and installing the JavaScript bridge.

### 1. Add the Gem

Add `tailmix` to your application's Gemfile:

```bash
bundle add tailmix
```

### 2. Install JavaScript Assets

Run the installer to set up the necessary JavaScript files for the client-side bridge (used by actions).

```bash
bin/rails g tailmix:install
```

This command will add tailmix to your importmap.rb and ensure its JavaScript is available in your application.

### Your First Component: A Badge
Let's create a simple BadgeComponent to see Tailmix in action.

#### 1. Define the Component Class
   
Create a new file in `app/components/badge_component.rb`:

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
        variant :gray,    "bg-gray-100 text-gray-600"
        variant :success, "bg-green-100 text-green-700"
        variant :danger,  "bg-red-100 text-red-700"
      end
    end
  end
end
```

#### 2. Use it in a View
   
Now, you can use this component in any ERB view:

```html
<%# Create two instances of our badge with different variants %>
<% success_badge = BadgeComponent.new("Active", color: :success) %>
<% danger_badge = BadgeComponent.new("Inactive", color: :danger) %>

<span <%= tag.attributes **success_badge.ui.badge %>>
  <%= success_badge.text %>
</span>

<span <%= tag.attributes **danger_badge.ui.badge %>>
  <%= danger_badge.text %>
</span>
```

#### View Usage .arb (Ruby Arbre)

```ruby
# app/views/components/_badge.arb
success_badge = BadgeComponent.new("Active", color: :success)
danger_badge = BadgeComponent.new("Inactive", color: :danger)

span success_badge.ui.badge do
  success_badge.text
end

span danger_badge.ui.badge do
  danger_badge.text
end
```

#### 3. The Resulting HTML
   
This will produce the following clean and semantic HTML:

```html
<span class="inline-flex ... bg-green-100 text-green-700" data-tailmix-badge="color:success">
  Active
</span>

<span class="inline-flex ... bg-red-100 text-red-700" data-tailmix-badge="color:danger">
  Inactive
</span>
```

Notice the `data-tailmix-badge` attribute, which serves as both a stable selector and a state indicator for your component.

## Next Steps

- You've successfully created your first component! To learn more about the power of Tailmix, check out these documents:

- DSL Reference: For a deep dive into every available DSL method.

- Cookbook: For practical, real-world examples of common UI components.

