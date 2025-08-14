# frozen_string_literal: true

require "ostruct"

module Tailmix
  module Resolver
    def self.call(schema, active_variants = {})
      resolved_parts = schema.elements.each_with_object({}) do |(element_name, element), result|
        class_list = []

        class_list << element.base_classes

        element.dimensions.each do |dimension_name, dimension|
          active_option = active_variants[dimension_name] || dimension.default_option

          if active_option
            variant_class = dimension.options[active_option]
            class_list << variant_class
          end
        end

        result[element_name] = class_list.compact.join(" ")
      end

      OpenStruct.new(resolved_parts)
    end
  end
end
