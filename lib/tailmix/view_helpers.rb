# lib/tailmix/view_helpers.rb
module Tailmix
  ##
  # Provides helper methods for rendering Tailmix component definitions and managing
  # Tailmix-related data attributes in view templates.
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

    # Renders a data attribute for a Tailmix trigger.
    # @example tailmix_trigger_for(:user_profile_modal, :toggle_open)
    def tailmix_trigger_for(target_id, action_name, event_name: :click)
      {
        "data-tailmix-trigger-for": target_id,
        "data-tailmix-action": "#{event_name}->#{action_name}"
      }
    end
  end
end
