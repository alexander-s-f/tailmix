# frozen_string_literal: true

module Tailmix
  class Dimension
    attr_reader :options, :default_option

    def initialize(&block)
      @options = {}
      @default_option = nil
      instance_eval(&block) if block_given?
    end

    def option(name, classes, default: false)
      @options[name.to_sym] = classes
      @default_option = name.to_sym if default
    end
  end
end
