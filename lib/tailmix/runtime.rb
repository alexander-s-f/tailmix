# frozen_string_literal: true

require_relative "element"
require_relative "action_proxy"
require_relative "stimulus_builder"

module Tailmix
  class Runtime
    attr_reader :definition

    def initialize(definition, options = {})
      @definition = definition
      @options = options
      @elements = {}

      build_elements!
    end

    def action(name)
      ActionProxy.new(self, name)
    end

    def stimulus(&block)
      builder = StimulusBuilder.new(@definition)
      yield builder
      builder.to_h
    end

    def method_missing(name, runtime_options = {}, &block)
      return super unless @elements.key?(name)
      return @elements[name] if runtime_options.empty?

      element_def = @definition.elements[name]
      merged_options = @options.merge(runtime_options)
      recalculated_classes = calculate_initial_classes(element_def, merged_options)

      Element.new(recalculated_classes, definition: @definition)
    end

    def respond_to_missing?(method_name, include_private = false)
      @elements.key?(method_name) || super
    end

    private

    def build_elements!
      @definition.elements.each do |name, element_def|
        initial_classes = calculate_initial_classes(element_def, @options)
        @elements[name] = Element.new(initial_classes, definition: @definition)
      end
    end

    def calculate_initial_classes(element_def, options_to_apply)
      classes = Set.new(element_def[:base])
      element_def[:options].each do |dimension_name, dimension_def|
        value_to_apply = options_to_apply.fetch(dimension_name, dimension_def[:default])
        next if value_to_apply.nil?
        classes_to_add = dimension_def[:options][value_to_apply]
        classes.merge(classes_to_add) if classes_to_add
      end
      classes.to_a
    end
  end
end
