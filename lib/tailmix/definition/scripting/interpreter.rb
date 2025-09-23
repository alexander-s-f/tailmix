# frozen_string_literal: true

# Require all operation modules
Dir[File.join(__dir__, "operations", "*.rb")].each { |file| require file }

module Tailmix
  module Definition
    module Scripting
      class Interpreter
        OPERATIONS = {
          # State
          set: Operations::State.method(:set),
          toggle: Operations::State.method(:toggle),
          increment: Operations::State.method(:increment),
          # Collections
          each: Operations::Each.method(:each),
          array_push: Operations::Collections.method(:array_push),
          array_remove_at: Operations::Collections.method(:array_remove_at),
          array_update_at: Operations::Collections.method(:array_update_at),
          array_remove_where: Operations::Collections.method(:array_remove_where),
          array_update_where: Operations::Collections.method(:array_update_where),
          # Logical
          and: Operations::Logical.method(:and),
          or: Operations::Logical.method(:or),
          not: Operations::Logical.method(:not),
          if: Operations::Logical.method(:if),
          # Interop
          call: Operations::Interop.method(:call),
          # Http
          fetch: Operations::Http.method(:fetch),
          # Arithmetic
          add: Operations::Arithmetic.method(:add),
          subtract: Operations::Arithmetic.method(:subtract),
          mod: Operations::Arithmetic.method(:mod),
          # Comparison
          eq: Operations::Comparison.method(:eq),
          lt: Operations::Comparison.method(:lt),
          gt: Operations::Comparison.method(:gt),
          # Value
          state: Operations::Value.method(:state),
          item: Operations::Value.method(:item),
          now: Operations::Value.method(:now),
          concat: Operations::Value.method(:concat),
          log: Operations::Value.method(:log),
          response: Operations::Value.method(:response),
          # Variables
          let: Operations::Variables.method(:let),
          var: Operations::Variables.method(:var),

          # DOM (placeholders)
          dom_append: Operations::Dom.method(:dom_append),
          dom_prepend: Operations::Dom.method(:dom_prepend),
          dom_add_class: Operations::Dom.method(:dom_add_class),
          dom_remove_class: Operations::Dom.method(:dom_remove_class),
          dom_toggle_class: Operations::Dom.method(:dom_toggle_class),
          dom_replace: Operations::Dom.method(:dom_replace),
          dom_remove: Operations::Dom.method(:dom_remove),
          dom_set_attribute: Operations::Dom.method(:dom_set_attribute),
          dom_set_value: Operations::Dom.method(:dom_set_value),

          # HTML
          html_build: Operations::Html.method(:html_build),
          element_attrs: Operations::Html.method(:element_attrs),
        }.freeze

        attr_reader :context, :actions_definition, :server_context
        attr_accessor :response_context

        def self.eval_all(expressions, context, actions_definition = {}, server_context = {})
          new(context, actions_definition, server_context).tap do |interpreter|
            expressions.each { |expr| interpreter.eval(expr) }
          end.context
        end

        def initialize(context, actions_definition = {}, server_context = {})
          @context = context.dup
          @actions_definition = actions_definition
          @server_context = server_context
          @response_context = nil
          @local_variables = {}
        end

        def eval(expression)
          op, *args = expression
          handler = OPERATIONS[op]
          raise Error, "Unknown operation: #{op}" unless handler
          handler.call(self, args)
        end

        def eval_with_response_context(expressions, response_context)
          self.response_context = response_context
          self.class.eval_all(expressions, @context, @actions_definition, @server_context)
          self.response_context = nil
        end

        def eval_branch(branch)
          return nil unless branch
          # Pass the actions_definition to the sub-evaluation
          self.class.eval_all(branch, @context, @actions_definition)
        end
      end
    end
  end
end
