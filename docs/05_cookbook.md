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
