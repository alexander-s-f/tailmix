# frozen_string_literal: true

module Tailmix
  # Stores the configuration for the Tailmix gem.
  class Configuration
    attr_accessor :element_selector_attribute

    def initialize
      @element_selector_attribute = nil
    end
  end
end
