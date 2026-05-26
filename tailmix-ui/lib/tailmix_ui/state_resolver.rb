# frozen_string_literal: true

module TailmixUi
  module StateResolver
    # Resolves a raw value (e.g., "completed", true, :pending) to a semantic state color.
    def self.resolve(value, default: :default)
      return default if value.nil?

      # Basic direct boolean / integer fallbacks
      case value
      when true, "true", 1, "1" then return :green
      when false, "false", 0, "0" then return :red
      end

      # String normalization
      val_string = value.to_s.parameterize.underscore
      mappings = TailmixUi.configuration.state_mappings

      # Match against configured arrays
      mappings.each do |state, list|
        return state.to_sym if list.include?(val_string)
      end

      default
    end
  end
end
