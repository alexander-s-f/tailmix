# frozen_string_literal: true

require "set"

module Tailmix
  module HTML
    # A simple, immutable structure for storing a set of attributes.
    AttributeSet = Struct.new(:classes, :data, :aria, :other, keyword_init: true) do
      def initialize(classes: Set.new, data: {}, aria: {}, other: {})
        super(classes: classes, data: data, aria: aria, other: other)
      end

      def merge(new_attributes)
        self.class.new(**self.to_h.merge(new_attributes))
      end
    end

    # Stateless service that transforms AttributeSet into a final hash for rendering.
    class Renderer
      def self.call(attribute_set)
        new(attribute_set).render
      end

      def initialize(attribute_set)
        @set = attribute_set
      end

      def render
        final_hash = @set.other.dup

        class_string = @set.classes.to_a.join(" ")
        final_hash["class"] = class_string unless class_string.empty?

        final_hash.merge!(render_data_map("data", @set.data))
        final_hash.merge!(render_data_map("aria", @set.aria))

        final_hash
      end

      private

      def render_data_map(prefix, hash, accumulator = {})
        hash.each do |key, value|
          current_key = "#{prefix}-#{key.to_s.tr('_', '-')}"
          if value.is_a?(Hash)
            render_data_map(current_key, value, accumulator)
          else
            serialized_value = value.is_a?(Enumerable) ? value.to_a.join(" ") : value
            accumulator[current_key] = serialized_value unless serialized_value.to_s.empty?
          end
        end
        accumulator
      end
    end
  end
end
