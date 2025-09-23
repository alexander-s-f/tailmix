# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Represents the result of the `dom.select(...)` query
      # and provides chaining methods for manipulation.
      class QueryResultProxy
        def initialize(builder, selector)
          @builder = builder
          @selector = selector
        end

        def append(html_expression)
          @builder.expressions << [ :dom_append, @selector, @builder.resolve_expressions(html_expression) ]
          self
        end

        def add_class(class_names)
          @builder.expressions << [ :dom_add_class, @selector, @builder.resolve_expressions(class_names) ]
          self
        end

        def remove
          @builder.expressions << [ :dom_remove, @selector ]
          self
        end

        def prepend(html_expression)
          @builder.expressions << [ :dom_prepend, @selector, @builder.resolve_expressions(html_expression) ]
          self
        end

        def replace(html_expression)
          @builder.expressions << [ :dom_replace, @selector, @builder.resolve_expressions(html_expression) ]
          self
        end

        def remove_class(class_names)
          @builder.expressions << [ :dom_remove_class, @selector, @builder.resolve_expressions(class_names) ]
          self
        end

        def toggle_class(class_name)
          @builder.expressions << [ :dom_toggle_class, @selector, @builder.resolve_expressions(class_name) ]
          self
        end

        def set_attribute(name, value)
          @builder.expressions << [ :dom_set_attribute, @selector, name, @builder.resolve_expressions(value) ]
          self
        end

        def clear_value
          # Set value to an empty string
          @builder.expressions << [ :dom_set_value, @selector, "" ]
          self
        end
      end
    end
  end
end
