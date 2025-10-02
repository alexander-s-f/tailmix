# frozen_string_literal: true

require "set"

module Tailmix
  class Compressor
    def self.call(definitions)
      new(definitions).compress
    end

    def initialize(definitions)
      @definitions = Marshal.load(Marshal.dump(definitions))
      @class_dictionary = {}
      @next_class_id = 0
    end

    def compress
      traverse_and_replace(@definitions)

      {
        dictionary: @class_dictionary.invert,
        components: @definitions
      }
    end

    private

    def traverse_and_replace(node)
      case node
      when Hash
        # This part is correct, it traverses hashes (like the main definition object)
        node.each do |key, value|
          if key == :variants && value.is_a?(Hash)
            value.transform_values! do |classes|
              classes.map { |cls| get_class_id(cls) }
            end
          else
            traverse_and_replace(value)
          end
        end
      when Array
        # This part is correct, it traverses arrays
        node.each { |item| traverse_and_replace(item) }
        # This is the missing piece. We need to handle our AST nodes (which are Structs).
      when Struct
        # For Structs, we iterate over their members to find our class arrays.
        node.each_pair do |key, value|
          if [ :base_classes, :variant_classes ].include?(key) && value.is_a?(Array)
            # Modify the struct's value directly
            node[key] = value.map { |cls| get_class_id(cls) }
          else
            # Recurse into other members
            traverse_and_replace(value)
          end
        end
      else
        puts "Compressing class: #{node.class} - node: #{node}"
      end
    end

    def get_class_id(class_name)
      @class_dictionary[class_name] ||= begin
        id = @next_class_id
        @next_class_id += 1
        id
      end
    end
  end
end
