# frozen_string_literal: true

require "json"
require_relative "dsl"

module Tailmix
  class Definition
    attr_reader :elements, :actions

    def initialize(&block)
      @elements = {}
      @actions = {}

      DSL.new(self).instance_eval(&block)
    end

    def to_h
      {
        elements: @elements,
        actions: @actions
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
