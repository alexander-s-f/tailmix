# frozen_string_literal: true

require_relative "resolver"
require_relative "part"
require_relative "utils"

module Tailmix
  class Manager
    def initialize(schema, initial_variants = {})
      @schema = schema
      @current_variants = {}
      @part_objects = {}

      defaults = get_defaults_from_schema
      combine(Utils.deep_merge(defaults, initial_variants))
    end

    def combine(variants_to_apply = {})
      @current_variants = Utils.deep_merge(@current_variants, variants_to_apply)
      rebuild_parts!
      self
    end

    def method_missing(method_name, *args, &block)
      part_name = method_name.to_sym
      if @part_objects.key?(part_name)
        @part_objects[part_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @part_objects.key?(method_name.to_sym) || super
    end

    private

    def rebuild_parts!
      resolved_struct = Resolver.call(@schema, @current_variants)
      @part_objects = {}

      resolved_struct.to_h.each do |part_name, class_string|
        @part_objects[part_name] = Part.new(class_string || "")
      end
    end

    def get_defaults_from_schema
      defaults = {}
      @schema.elements.each_value do |element|
        element.dimensions.each do |dim_name, dim|
          defaults[dim_name] = dim.default_option if dim.default_option
        end
      end
      defaults
    end
  end
end
