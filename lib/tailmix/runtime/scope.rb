# frozen_string_literal: true

module Tailmix
  module Runtime
    # Manages a stack of variable scopes ("frames") to implement lexical scoping.
    # When looking for a variable, it searches from the innermost scope outwards.
    class Scope
      def initialize(global_vars = {})
        @stack = [ global_vars.transform_keys(&:to_sym) ]
      end

      # Pushes a new, empty scope onto the stack for local variables.
      def push(local_vars = {})
        @stack.push(local_vars.transform_keys(&:to_sym))
      end

      # Pops the current scope off the stack.
      def pop
        raise "Cannot pop the global scope" if @stack.length <= 1
        @stack.pop
      end

      # Defines a new variable in the *current* (innermost) scope.
      # Used by `let`.
      def define(name, value)
        @stack.last[name.to_sym] = value
      end

      # Finds an existing variable in the scope chain and updates its value.
      # Raises an error if the variable is not found. Used by `set`.
      def set(name, value)
        key = name.to_sym
        scope_level = @stack.rindex { |frame| frame.key?(key) }
        raise "Undefined variable `#{name}`. Cannot set value." unless scope_level

        @stack[scope_level][key] = value
      end

      # Finds a variable by searching from the innermost scope to the global scope.
      def find(name)
        key = name.to_sym
        @stack.reverse_each do |frame|
          return frame[key] if frame.key?(key)
        end
        nil
      end

      # A convenience method to execute a block within a new, temporary scope.
      def in_new_scope(vars = {})
        push(vars)
        yield self
      ensure
        pop
      end
    end
  end
end
