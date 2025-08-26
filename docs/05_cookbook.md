# Cookbook

This document contains practical recipes for building common UI components with Tailmix.

## Alert Component

Alerts are used to communicate a state that affects the entire system, feature, or page.

### 1. Component Definition

Here's the Ruby code for a flexible `AlertComponent`.

```ruby
# app/components/alert_component.rb
class AlertComponent
  include Tailmix
  attr_reader :ui, :icon_svg, :message

  def initialize(intent: :info, message:)
    @ui = tailmix(intent: intent)
    @message = message
    @icon_svg = fetch_icon(intent) # Logic to get the correct SVG icon
  end

  private

  def fetch_icon(intent)
    # ...
  end

  tailmix do
    element :wrapper, "flex items-center p-4 text-sm border rounded-lg" do
      dimension :intent, default: :info do
        variant :info,    "text-blue-800 bg-blue-50 border-blue-300"
        variant :success, "text-green-800 bg-green-50 border-green-300"
        variant :warning, "text-yellow-800 bg-yellow-50 border-yellow-300"
        variant :danger,  "text-red-800 bg-red-50 border-red-300"
      end
    end

    element :icon, "flex-shrink-0 w-5 h-5"
    element :message_area, "ml-3"
  end
end
```

#### View Usage (ERB)
Instantiate the component in your controller or view and use the ui helper to render the elements.

```html
<%# Success Alert %>
<% success_alert = AlertComponent.new(intent: :success, message: "Your profile has been updated.") %>

<div <%= tag.attributes **success_alert.ui.wrapper %>>
  <div <%= tag.attributes **success_alert.ui.icon %>>
    <%= success_alert.icon_svg.html_safe %>
  </div>
  <div <%= tag.attributes **success_alert.ui.message_area %>>
    <%= success_alert.message %>
  </div>
</div>


<%# Danger Alert %>
<% danger_alert = AlertComponent.new(intent: :danger, message: "Failed to delete the record.") %>

<div <%= tag.attributes **danger_alert.ui.wrapper %>>
  <div <%= tag.attributes **danger_alert.ui.icon %>>
    <%= danger_alert.icon_svg.html_safe %>
  </div>
  <div <%= tag.attributes **danger_alert.ui.message_area %>>
    <%= danger_alert.message %>
  </div>
</div>
```

#### View Usage .arb (Ruby Arbre)

```ruby
# Success Alert
success_alert = AlertComponent.new(intent: :success, message: "Your profile has been updated.")
ui = success_alert.ui

div ui.wrapper do
  div ui.icon do
    success_alert.icon_svg.html_safe
  end
  div ui.message_area do
    success_alert.message
  end
end

# Danger Alert
danger_alert = AlertComponent.new(intent: :danger, message: "Failed to delete the record.")
ui = danger_alert.ui

div ui.wrapper do
  div ui.icon do
    danger_alert.icon_svg.html_safe
  end
  div ui.message_area do
    danger_alert.message
  end
end
```

## Badge Component

Badges are used for labeling, categorization, or highlighting small pieces of information. This recipe shows how to combine multiple dimensions like `size` and `color`.

### 1. Component Definition

```ruby
# app/components/badge_component.rb
class BadgeComponent
  include Tailmix
  attr_reader :ui, :text

  def initialize(text, color: :gray, size: :sm)
    @ui = tailmix(color: color, size: size)
    @text = text
  end

  tailmix do
    element :badge, "inline-flex items-center font-medium rounded-full" do
      dimension :color, default: :gray do
        variant :gray,    "bg-gray-100 text-gray-600"
        variant :success, "bg-green-100 text-green-700"
        variant :warning, "bg-yellow-100 text-yellow-700"
        variant :danger,  "bg-red-100 text-red-700"
      end

      dimension :size, default: :sm do
        variant :sm, "px-2.5 py-0.5 text-xs"
        variant :md, "px-3 py-1 text-sm"
      end
    end
  end
end
```

#### View Usage (ERB)

```html
<%# A medium-sized success badge %>
<% success_badge = BadgeComponent.new("Active", color: :success, size: :md) %>
<span <%= tag.attributes **success_badge.ui.badge %>>
  <%= success_badge.text %>
</span>

<%# A small danger badge %>
<% danger_badge = BadgeComponent.new("Inactive", color: :danger, size: :sm) %>
<span <%= tag.attributes **danger_badge.ui.badge %>>
  <%= danger_badge.text %>
</span>
```

#### View Usage .arb (Ruby Arbre)

```ruby
# A medium-sized success badge
success_badge = BadgeComponent.new("Active", color: :success, size: :md)
ui = success_badge.ui

span ui.badge do
  success_badge.text
end

# A small danger badge
danger_badge = BadgeComponent.new("Inactive", color: :danger, size: :sm)
ui = danger_badge.ui

span ui.badge do
  danger_badge.text
end
```

## Card Component

Cards are flexible containers for content. This recipe shows how to build a component with multiple parts (`header`, `body`, `footer`) using multiple `element` definitions.

### 1. Component Definition

```ruby
# app/components/card_component.rb
class CardComponent
  include Tailmix
  attr_reader :ui

  # We can control the footer's top border with an option
  def initialize(with_divider: true)
    @ui = tailmix(with_divider: with_divider)
  end

  tailmix do
    element :wrapper, "bg-white border rounded-lg shadow-sm"
    element :header, "p-4 border-b"
    element :body, "p-4"
    element :footer, "p-4 bg-gray-50 rounded-b-lg" do
      dimension :with_divider, default: true do
        variant true, "border-t"
        variant false, "" # No border
      end
    end
  end
end
```

#### View Usage (ERB)

```html
<% card = CardComponent.new %>

<div <%= tag.attributes **card.ui.wrapper %>>
  <div <%= tag.attributes **card.ui.header %>>
    <h3 class="text-lg font-medium">Card Title</h3>
  </div>

  <div <%= tag.attributes **card.ui.body %>>
    <p>This is the main content of the card. It can contain any information you need to display.</p>
  </div>

  <div <%= tag.attributes **card.ui.footer %>>
    <button type="button">Action Button</button>
  </div>
</div>
```

#### View Usage .arb (Ruby Arbre)

```ruby
# Card
card = CardComponent.new
ui = card.ui

div ui.wrapper do
  div ui.header do
    h3 "Card Title"
  end

  div ui.body do
    para "This is the main content of the card. It can contain any information you need to display."
  end
  
  div ui.footer do
    button "Action Button"
  end
end
```