require "json"

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

    # Generates a hash of attributes for an external trigger that will control a named component instance.
    #
    # @param target_id [String, Symbol] Target component ID.
    # @param action_name [String, Symbol] The name of the action to be called.
    # @param options [Hash]
    # @return [Hash]
    def tailmix_trigger_for(target_id, action_name, options)
      # target_id = options.fetch(:target_id)
      # action_name = options.fetch(:action_name)

      event_name = options.fetch(:event_name, :click)
      with = options.fetch(:with, nil)

      attributes = {
        "data-tailmix-trigger-for" => target_id.to_s,
        "data-tailmix-action" => "#{event_name}->#{action_name}"
      }

      if with
        attributes["data-tailmix-action-payload"] = with.to_json
      end

      attributes
    end
  end
end
