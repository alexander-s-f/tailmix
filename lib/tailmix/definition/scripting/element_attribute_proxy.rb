# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Represents a reference to the element (el.task_item) and allows
      # adding scope via .with().
      class ElementAttributeProxy
        def initialize(element_name)
          @element_name = element_name
          @with_data = {}
        end

        def with(data)
          @with_data.merge!(data)
          self
        end

        # Converts the object into an S-expression for transmission to the client
        def to_a
          [ :element_attrs, @element_name, @with_data ]
        end
      end
    end
  end
end
