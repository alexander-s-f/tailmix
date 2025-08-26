# The Client-Side Bridge

Tailmix is primarily a server-side tool, but it includes a powerful "bridge" to your client-side JavaScript, enabling dynamic and optimistic UI updates. This bridge operates on several levels.

## Level 1: The State Bridge

Every element defined in Tailmix automatically receives a `data-tailmix-*` attribute.

```html
<button data-tailmix-button="size:md,intent:primary">
  Click Me
</button>
```

This attribute serves two purposes:

1. A Stable Selector: You can reliably select this element in your JavaScript with `document.querySelector('[data-tailmix-button]')`. This is used internally by Tailmix actions.

2. A State Indicator: The value of the attribute reflects the currently applied variants. Your JavaScript can read this to understand the element's state without needing extra data attributes.

**Example: Reading State in Stimulus**

```js
// button_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        // e.g., "size:md,intent:primary"
        const variants = this.element.dataset.tailmixButton;
        console.log("Current button variants:", variants);

        if (variants.includes("size:md")) {
            // do something specific for medium buttons
        }
    }
}
```

## Level 2: The Action Bridge

This is the most powerful part of the bridge, allowing you to execute UI mutations defined in Ruby directly on the client.

1. Define an `actio`n in Ruby
   
First, define an `action` in your component. This action describes a set of changes to apply to different elements.

```ruby
# app/components/form_component.rb
class FormComponent
  include Tailmix
  tailmix do
    element :submit_button
    element :spinner, "hidden"

    action :show_pending_state, method: :add do
      element :submit_button do
        classes "opacity-50 cursor-not-allowed"
      end
      element :spinner do
        classes "hidden", method: :remove # override default method
      end
    end
  end
end
```

2. Expose it with action_payload
   
Use the `action_payload` helper in your `stimulus` block to serialize the action's definition into a Stimulus value.

```ruby
# ...inside the :submit_button element
stimulus
  .controller("form")
  .action(:click, :submit)
  .action_payload(:show_pending_state, as: :pending_data)
```

This will generate `data-form-pending-data-value="{...}"` containing the JSON definition of your `:show_pending_state` action.

3. Run it from Stimulus

In your Stimulus controller, import `Tailmix` and call `Tailmix.run()` with the action's config.

```js
// form_controller.js
import { Controller } from "@hotwired/stimulus"
import Tailmix from "tailmix"

export default class extends Controller {
    static values = { pendingData: Object }

    submit(event) {
        event.preventDefault();

        // Instantly apply the UI changes defined in Ruby
        Tailmix.run({
            config: this.pendingDataValue,
            controller: this
        });

        // ... now submit the form via fetch/AJAX ...
    }
}
```

When `submit` is called, the button's classes will be changed and the spinner will be shown instantly, creating a fast, optimistic UI update.

## Level 3: The Definition Bridge (Future Vision)

The ultimate goal is to allow the client to have access to the full `variant` and `compound_variant` definitions. This would enable the client to dynamically switch between any variant combination without a server roundtrip, providing a SPA-like experience.

This is a complex feature planned for a future release and will likely involve passing the definitions via an inline `<script type="application/json">` tag to keep the component's HTML clean.





