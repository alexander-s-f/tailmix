# frozen_string_literal: true

module Tailmix
  module Scripting
    # The Builder provides a high-level DSL for generating S-expressions.
    # An instance of this builder is passed to the `action` and `reaction` blocks
    # in the component definition.
    class Builder
      attr_reader :expressions

      def initialize(component_builder)
        @component_builder = component_builder
        @expressions = []
      end

      # Calls another action by its name.
      def call(action_name, payload = {})
        # For now, payload is not implemented, but we reserve the API.
        @expressions << [ :call, action_name ]
        self
      end

      # Finds and expands a macro by its name.
      def expand_macro(name, *args)
        macro_def = @component_builder.macros[name.to_sym]
        raise Error, "Macro '#{name}' not found." unless macro_def
        macro_builder = self.class.new(@component_builder)
        macro_builder.instance_exec(*args, &macro_def[:block])
        @expressions.concat(macro_builder.expressions)
        self
      end

      # --- State Manipulation ---

      def set(key, value)
        @expressions << [ :set, key, value ]
        self
      end

      def toggle(key)
        @expressions << [ :toggle, key ]
        self
      end

      def increment(key, by: 1)
        @expressions << [ :increment, key, by ]
        self
      end

      # --- Collection Manipulation ---

      def push(key, value)
        @expressions << [ :array_push, key, value ]
        self
      end

      def remove_at(key, index)
        @expressions << [ :array_remove_at, key, index ]
        self
      end

      def update_at(key, index, value)
        @expressions << [ :array_update_at, key, index, value ]
        self
      end

      # --- Server Interaction ---

      def fetch(url, then: nil, catch: nil, params: {})
        options = { "then": binding.local_variable_get(:then), catch: binding.local_variable_get(:catch), params: params }.compact
        @expressions << [ :fetch, url, options ]
        self
      end

      # --- Control Flow ---

      def if_(condition)
        then_builder = self.class.new(@component_builder)
        yield(then_builder)

        # .to_a unfolds ExpressionBuilder back into an S-expression
        @expressions << [ :if, condition.to_a, then_builder.expressions ]
        self
      end
      alias_method :if?, :if_

      def not_(expression)
        [ :not, expression.to_a ]
      end
      alias_method :not?, :not_

      def state(key)
        ExpressionBuilder.new([ :state, key ])
      end

      def concat(*args)
        # This is a value-producing method, so it returns an S-expression
        # instead of adding one to the @expressions list.
        [ :concat, *args ]
      end

      def now
        [ :now ]
      end

      # --- Debugging ---

      def log(*args)
        @expressions << [ :log, *args ]
        self
      end
    end
  end
end
