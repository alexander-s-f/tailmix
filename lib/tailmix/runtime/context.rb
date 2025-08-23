# frozen_string_literal: true

module Tailmix
  module Runtime
    class Context
      attr_reader :component_instance, :definition, :dimensions

      def initialize(component_instance, definition, dimensions)
        @component_instance = component_instance
        @definition = definition
        @dimensions = dimensions
        @attributes_cache = {}
      end

      def initialize_copy(source)
        super
        @attributes_cache = source.instance_variable_get(:@attributes_cache).transform_values(&:dup)
      end

      def live_attributes_for(element_name)
        @attributes_cache[element_name] ||= build_attributes_for(element_name, @dimensions)
      end

      def attributes_for(element_name, runtime_dimensions = {})
        merged_dimensions = @dimensions.merge(runtime_dimensions)
        return @attributes_cache[element_name] if merged_dimensions == @dimensions && @attributes_cache[element_name]

        attributes_object = build_attributes_for(element_name, merged_dimensions)
        @attributes_cache[element_name] = attributes_object if merged_dimensions == @dimensions
        attributes_object
      end

      def action(name)
        Action.new(self, name)
      end

      private

      def build_attributes_for(element_name, dimensions)
        element_def = @definition.elements.fetch(element_name)
        initial_classes = element_def.attributes.classes
        class_list = HTML::ClassList.new(initial_classes)

        element_def.dimensions.each do |name, dim|
          value = dimensions.fetch(name, dim[:default])
          next if value.nil?
          classes_for_option = dim.fetch(:options, {}).fetch(value, nil)
          class_list.add(classes_for_option)
        end

        data_map = HTML::DataMap.new
        Stimulus::Compiler.call(
          definition: element_def.stimulus,
          data_map: data_map,
          root_definition: @definition,
          component: @component_instance
        )

        HTML::Attributes.new(
          { class: class_list, data: data_map },
          element_name: element_def.name
        )
      end
    end
  end
end
