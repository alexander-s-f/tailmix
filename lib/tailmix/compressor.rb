# frozen_string_literal: true

require "set"

module Tailmix
  class Compressor
    def self.call(definitions)
      new(definitions).compress
    end

    def initialize(definitions)
      @definitions = definitions
      @class_dictionary = {}
      @next_class_id = 0
    end

    def compress
      # Cloning to avoid modifying the original object in the Registry
      compressed_definitions = deep_clone(@definitions)

      # Recursively find all classes and build a dictionary
      traverse_and_build_dictionary(compressed_definitions)

      {
        dictionary: @class_dictionary.invert, # { 0 => "class-a", 1 => "class-b" }
        components: compressed_definitions
      }
    end

    private

    def traverse_and_build_dictionary(node)
      case node
      when Hash
        node.each do |key, value|
          if (key == :classes || key == :base_classes) && value.is_a?(Array)
            node[key] = value.map { |cls| get_class_id(cls) }
          else
            traverse_and_build_dictionary(value)
          end
        end
      when Array
        node.each { |item| traverse_and_build_dictionary(item) }
      end
    end

    def get_class_id(class_name)
      @class_dictionary[class_name] ||= begin
        id = @next_class_id
        @next_class_id += 1
        id
      end
    end

    def deep_clone(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end
end
