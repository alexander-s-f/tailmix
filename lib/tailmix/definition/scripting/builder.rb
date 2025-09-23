# frozen_string_literal: true

require_relative "expression_builder"
require_relative "response_builder"
require_relative "payload_proxy"
require_relative "event_proxy"
require_relative "state_root_proxy"
require_relative "variable_proxy"
require_relative "element_proxy"
require_relative "dom_proxy"
require_relative "html_builder_proxy"
require_relative "helpers"

module Tailmix
  module Definition
    module Scripting
      class Builder
        include Helpers

        attr_reader :expressions
        attr_reader :component_builder

        def initialize(component_builder)
          @component_builder = component_builder
          @expressions = []
        end

        def call(action_name, payload = {})
          @expressions << [ :call, action_name, resolve_expressions(payload) ]
          self
        end

        def state
          StateRootProxy.new(self)
        end
        alias_method :s, :state

        def payload
          PayloadProxy.new
        end

        def event
          EventProxy.new
        end

        def el
          @_element_proxy ||= ElementProxy.new
        end

        def dom
          @_dom_proxy ||= DomProxy.new(self)
        end

        def html
          @_html_proxy ||= HtmlBuilderProxy.new(self)
        end

        def expand_macro(name, *args)
          macro_def = @component_builder.macros[name.to_sym]
          raise Error, "Macro '#{name}' not found." unless macro_def

          macro_builder = self.class.new(@component_builder)
          resolved_args = args.map { |arg| resolve_expressions(arg) }
          macro_builder.instance_exec(*resolved_args, &macro_def[:block])

          @expressions.concat(macro_builder.expressions)
          self
        end

        def fetch(url, method: :get, params: {}, service: nil, &block)
          options = {
            url: url,
            method: method,
            params: resolve_expressions(params),
            service: service&.to_s
          }.compact

          callback_builder = self.class.new(@component_builder)
          response_builder = ResponseBuilder.new
          callback_builder.instance_exec(response_builder, &block)

          @expressions << [ :fetch, options, callback_builder.expressions ]
          self
        end

        # --- State & Collection Methods ---

        def set(key, value)
          @expressions << [ :set, key, resolve_expressions(value) ]
          self
        end

        def toggle(key)
          @expressions << [ :toggle, key ]
          self
        end

        def increment(key, by: 1)
          @expressions << [ :increment, key, resolve_expressions(by) ]
          self
        end
        alias_method :inc, :increment

        def push(key, value)
          @expressions << [ :array_push, key, resolve_expressions(value) ]
          self
        end

        def remove_at(key, index)
          @expressions << [ :array_remove_at, key, resolve_expressions(index) ]
          self
        end

        def update_at(key, index, value)
          @expressions << [ :array_update_at, resolve_expressions(index), resolve_expressions(value) ]
          self
        end

        def remove_where(key, query)
          @expressions << [ :array_remove_where, key, resolve_expressions(query) ]
        end

        def update_where(key, query, data)
          @expressions << [ :array_update_where, key, resolve_expressions(query), resolve_expressions(data) ]
        end

        # --- Control Flow & Value Methods ---

        def if_(condition, &block)
          then_builder = self.class.new(@component_builder)
          yield(then_builder)
          @expressions << [ :if, resolve_expressions(condition), then_builder.expressions ]
          self
        end
        alias_method :if?, :if_

        def not_(expression)
          [ :not, resolve_expressions(expression) ]
        end
        alias_method :not?, :not_

        def concat(*args)
          [ :concat, *args.map { |arg| resolve_expressions(arg) } ]
        end

        # --- Local Variables ---

        # let :user_name, state.user.name
        def let(variable_name, value_expression)
          @expressions << [:let, variable_name.to_sym, resolve_expressions(value_expression)]
          self
        end

        def var
          @_variable_proxy ||= VariableProxy.new
        end

        def log(*args)
          @expressions << [ :log, *args.map { |arg| resolve_expressions(arg) } ]
          self
        end
      end
    end
  end
end
