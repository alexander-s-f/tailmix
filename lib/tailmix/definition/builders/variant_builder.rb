# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      class VariantBuilder
        def initialize
          @class_groups = []
          @data = {}
          @aria = {}
          @attributes = {}
        end

        def classes(class_string, options = {})
          @class_groups << { classes: class_string.to_s.split, options: options }
        end

        def data(hash)
          @data.merge!(hash)
        end

        def aria(hash)
          @aria.merge!(hash)
        end

        def method_missing(name, *args, &block)
          # `disabled true` -> { disabled: true }
          # `placeholder "text"` -> { placeholder: "text" }
          # `type "password"` -> { type: "password" }
          attribute_name = name.to_s.chomp("=").to_sym
          value = args.first
          @attributes[attribute_name] = value
        end

        def respond_to_missing?(*_args)
          true
        end

        def build_variant
          Definition::Result::Variant.new(
            class_groups: @class_groups.freeze,
            data: @data.freeze,
            aria: @aria.freeze,
            attributes: @attributes.freeze
          )
        end
      end
    end
  end
end
