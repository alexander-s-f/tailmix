# frozen_string_literal: true

module Tailmix
  # Stores the configuration for the Tailmix gem.
  class Configuration
    attr_accessor :element_selector_attribute, :dev_mode_attributes

    def initialize
      @element_selector_attribute = nil
      @dev_mode_attributes = defined?(Rails) && Rails.env.development?
    end
  end
end
