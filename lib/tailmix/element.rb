# frozen_string_literal: true

require "set"

module Tailmix
  class Element

    def initialize(initial_classes = [], definition:)
      @classes = Set.new(initial_classes)
      @definition = definition
    end

    def add(new_classes)
      @classes.merge(parse_classes(new_classes))
      self # chaining, e.g. ui.container.add(...).remove(...)
    end

    def remove(classes_to_remove)
      @classes.subtract(parse_classes(classes_to_remove))
      self
    end

    def toggle(classes_to_toggle)
      parse_classes(classes_to_toggle).each do |klass|
        @classes.include?(klass) ? @classes.delete(klass) : @classes.add(klass)
      end
      self
    end

    def stimulus(&block)
      builder = StimulusBuilder.new(@definition, element: self)
      yield builder
      builder.to_h
    end

    def to_s
      @classes.to_a.join(" ")
    end

    def to_h
      { class: to_s }
    end

    def inspect
      "#<Tailmix::Element classes=\"#{to_s}\">"
    end

    private

    def parse_classes(input)
      return input.split if input.is_a?(String)

      Array(input).flatten.map(&:to_s)
    end
  end
end
