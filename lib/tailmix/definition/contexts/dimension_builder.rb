# frozen_string_literal: true

module Tailmix
  module Definition
    module Contexts
      class DimensionBuilder
        attr_reader :options

        def initialize
          @options = { options: {}, default: nil }
        end

        def option(value, classes, default: false)
          @options[:options][value] = classes.split
          @options[:default] = value if default
        end
      end
    end
  end
end
