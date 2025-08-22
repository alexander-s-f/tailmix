# frozen_string_literal: true

require "set"

module Tailmix
  module HTML
    # Manages a set of CSS classes with a fluent, chainable API.
    # Inherits from Set to ensure uniqueness and leverage its performance.
    class ClassList < Set
      # Initializes a new ClassList.
      # @param initial_classes [String, Array, Set, nil] The initial classes to add.
      def initialize(initial_classes = nil)
        super()
        add(initial_classes) if initial_classes
      end

      # Adds one or more classes. Handles strings, arrays, or other sets.
      # This method is MUTABLE and chainable.
      # @param class_names [String, Array, Set, nil]
      # @return [self]
      def add(class_names)
        each_token(class_names) { |token| super(token) }
        self
      end
      alias << add

      # Removes one or more classes.
      # This method is MUTABLE and chainable.
      # @param class_names [String, Array, Set, nil]
      # @return [self]
      def remove(class_names)
        each_token(class_names) { |token| delete(token) }
        self
      end

      # Toggles one or more classes.
      # This method is MUTABLE and chainable.
      # @param class_names [String, Array, Set, nil]
      # @return [self]
      def toggle(class_names)
        each_token(class_names) { |token| include?(token) ? delete(token) : add(token) }
        self
      end

      # Returns a new ClassList with the given classes added. IMMUTABLE.
      def added(class_names)
        dup.add(class_names)
      end

      # Returns a new ClassList with the given classes removed. IMMUTABLE.
      def removed(class_names)
        dup.remove(class_names)
      end

      # Returns a new ClassList with the given classes toggled. IMMUTABLE.
      def toggled(class_names)
        dup.toggle(class_names)
      end

      # Renders the set of classes to a space-separated string for HTML.
      # @return [String]
      def to_s
        to_a.join(" ")
      end

      private

      # A robust way to iterate over tokens from various input types.
      def each_token(input)
        return unless input
        # Convert Set/ClassList to array before splitting strings inside
        items = input.is_a?(Set) ? input.to_a : Array(input)
        items.each do |item|
          item.to_s.split.each { |token| yield token unless token.empty? }
        end
      end
    end
  end
end
