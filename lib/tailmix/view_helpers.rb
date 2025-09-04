# lib/tailmix/view_helpers.rb
module Tailmix
  module ViewHelpers
    # Renders a script tag containing the definitions for all unique
    # Tailmix components used on the current page.
    def tailmix_definitions_tag
      definitions = Tailmix::Registry.instance.definitions
      return if definitions.empty?

      json_payload = definitions.to_json

      tag.script(
        type: "application/json",
        "data-tailmix-definitions": "true"
      ) do
        json_payload.html_safe
      end
    end
  end
end
