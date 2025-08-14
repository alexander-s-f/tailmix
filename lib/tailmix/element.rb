# frozen_string_literal: true

require_relative "dimension"

module Tailmix
  class Element
    attr_reader :base_classes, :dimensions

    def initialize(base_classes, &block)
      @base_classes = base_classes
      @dimensions = {}
      instance_eval(&block) if block_given?
    end

    def method_missing(method_name, &block)
      dimension_name = method_name.to_sym
      @dimensions[dimension_name] = Dimension.new(&block)
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end
  end
end
