# frozen_string_literal: true
require "singleton"
require "set"

module Tailmix
  # A per-request registry to store unique component classes rendered
  # during a request-response cycle.
  class Registry
    include Singleton

    def initialize
      @component_classes = Set.new
    end

    # Registers a component class.
    # @param component_class [Class] The component class to register.
    def register(component_class)
      @component_classes.add(component_class)
    end

    # Gathers definitions from all registered classes.
    # @return [Hash] A hash mapping component names to their definitions.
    def definitions
      @component_classes.each_with_object({}) do |klass, hash|
        component_name = klass.name
        if component_name && klass.respond_to?(:tailmix_definition)
          hash[component_name] = klass.tailmix_definition.to_h
        end
      end
    end

    # Clears the registry. Must be called after each request.
    def clear!
      @component_classes.clear
    end
  end
end
