# frozen_string_literal: true

module Tailmix
  module Definition
    # A service object responsible for deep-merging two tailmix definitions.
    class Merger
      def self.call(parent_def, child_def)
        new(parent_def, child_def).merge
      end

      def initialize(parent_def, child_def)
        @parent_def = parent_def
        @child_def = child_def
      end

      def merge
        Result::Context.new(
          elements: merged_elements,
          actions: merged_actions
        )
      end

      private

      def merged_actions
        # For actions, child definitions completely override parent definitions.
        @parent_def.actions.merge(@child_def.actions)
      end

      def merged_elements
        all_element_keys = (@parent_def.elements.keys | @child_def.elements.keys)

        all_element_keys.each_with_object({}) do |key, h|
          parent_element = @parent_def.elements[key]
          child_element = @child_def.elements[key]

          h[key] = if parent_element && child_element
            merge_element(parent_element, child_element)
          else
            child_element || parent_element
          end
        end
      end

      def merge_element(parent_el, child_el)
        Result::Element.new(
          name: parent_el.name,
          attributes: merge_attributes(parent_el.attributes, child_el.attributes),
          dimensions: merge_dimensions(parent_el.dimensions, child_el.dimensions),
          stimulus: merge_stimulus(parent_el.stimulus, child_el.stimulus)
        )
      end

      def merge_attributes(parent_attrs, child_attrs)
        # Combine base classes, ensuring no duplicates.
        combined_classes = (parent_attrs.classes + child_attrs.classes).uniq
        Result::Attributes.new(classes: combined_classes)
      end

      def merge_stimulus(parent_stimulus, child_stimulus)
        # Combine stimulus definitions.
        combined_definitions = parent_stimulus.definitions + child_stimulus.definitions
        Result::Stimulus.new(definitions: combined_definitions)
      end

      private

      def merge_dimensions(parent_dims, child_dims)
        deep_merge(parent_dims, child_dims) do |key, parent_val, child_val|
          if key == :options && parent_val.is_a?(Hash) && child_val.is_a?(Hash)
            parent_val.merge(child_val)
          else
            child_val
          end
        end
      end

      def deep_merge(parent_hash, child_hash, &block)
        child_hash.each_with_object(parent_hash.dup) do |(key, child_val), new_hash|
          parent_val = new_hash[key]

          new_hash[key] = if parent_val.is_a?(Hash) && child_val.is_a?(Hash)
            deep_merge(parent_val, child_val, &block)
          elsif block_given? && new_hash.key?(key)
            block.call(key, parent_val, child_val)
          else
            child_val
          end
        end
      end
    end
  end
end
