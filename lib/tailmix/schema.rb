# frozen_string_literal: true

require_relative "element"

module Tailmix
  class Schema
    attr_reader :elements, :actions

    def initialize(&block)
      @elements = {}
      @actions = {}
      instance_eval(&block) if block_given?
    end

    def element(name, base_classes, &block)
      @elements[name.to_sym] = Element.new(base_classes, &block)
    end

    def action(name, behavior: :toggle, &block)
      builder = ActionBuilder.new
      builder.instance_eval(&block)

      @actions[name.to_sym] = {
        behavior: behavior,
        classes_by_part: builder.classes_by_part
      }
    end

    class ActionBuilder
      attr_reader :classes_by_part

      def initialize
        @classes_by_part = {}
      end

      def element(name, classes)
        @classes_by_part[name.to_sym] = classes
      end
    end
  end
end
