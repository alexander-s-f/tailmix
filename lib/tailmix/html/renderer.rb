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
        final_hash = @set.other.dup.compact.except(:content)

        class_string = @set.classes.to_a.join(" ")
        final_hash["class"] = class_string unless class_string.empty?

        # Pass only the hash, the prefix is known.
        final_hash.merge!(render_map("data", @set.data))
        final_hash.merge!(render_map("aria", @set.aria))

        final_hash
      end

      # This is what we need for `bind :text` to work on the server.
      def content
        @set.other[:content]
      end

      private

      def render_map(prefix, hash)
        accumulator = {}
        hash.each do |key, value|
          next if value.nil?
          # Always construct the key from scratch
          current_key = "#{prefix}-#{key.to_s.tr('_', '-')}"
          serialized_value = value.is_a?(Enumerable) ? value.to_a.join(" ") : value.to_s
          accumulator[current_key] = serialized_value unless serialized_value.empty?
        end
        accumulator
      end
    end
  end
end
