# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Provides access to the fields of a single item within an `each` loop,
      # allowing for the creation of S-expressions that are bound to item data.
      class ItemBuilder
        def initialize(iterator_name)
          @iterator_name = iterator_name
        end

        # Handles calls like `task.title`, `task.id`, etc.
        def method_missing(method_name, *args, &block)
          # Creates an S-expression like [:item, :title]
          ExpressionBuilder.new([:item, method_name.to_sym])
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end
  end
end
