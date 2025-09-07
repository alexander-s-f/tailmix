# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      class VariantBuilder
        def initialize
          @class_groups = []
          @data = {}
          @aria = {}
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

        def build_variant
          Definition::Result::Variant.new(
            class_groups: @class_groups.freeze,
            data: @data.freeze,
            aria: @aria.freeze
          )
        end
      end
    end
  end
end
