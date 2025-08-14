# frozen_string_literal: true

require_relative "element"

module Tailmix
  class Schema
    attr_reader :elements

    def initialize(&block)
      @elements = {}
      instance_eval(&block) if block_given?
    end

    def element(name, base_classes, &block)
      @elements[name.to_sym] = Element.new(base_classes, &block)
    end
  end
end
