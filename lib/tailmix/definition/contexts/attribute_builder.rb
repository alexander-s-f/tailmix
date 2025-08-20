# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      class AttributeBuilder
        def initialize
          @classes = []
        end

        def classes(*list)
          @classes.concat(list.flatten.map(&:to_s))
        end

        def build_definition
          Definition::Result::Attributes.new(classes: @classes.freeze)
        end
      end
    end
  end
end
