# frozen_string_literal: true

require_relative "response_builder"
require_relative "param_proxy"
require_relative "this_proxy"
require_relative "html_builder_proxy"
require_relative "helpers"

module Tailmix
  module Definition
    module Scripting
      class Builder
        include Helpers

        attr_reader :expressions, :component_builder, :main_builder
        attr_accessor :cursor

        def initialize(component_builder, main_builder: nil)
          @component_builder = component_builder
          @main_builder = main_builder || self
          @expressions = []
          @cursor = nil
        end

        def set(key_expr, value_expr)
          @main_builder.expressions << [ :set, resolve_expressions(key_expr), resolve_expressions(value_expr) ]
          @main_builder
        end

        def increment(by = 1)
          raise "increment can only be called on a state variable expression" unless @cursor&.first == :state
          @main_builder.expressions << [ :increment, @cursor[1], resolve_expressions(by) ]
          @main_builder
        end

        def toggle
          raise "toggle can only be called on a state variable expression" unless @cursor&.first == :state
          @main_builder.expressions << [ :toggle, @cursor[1] ]
          @main_builder
        end

        def if_(condition, &block)
          then_builder = self.class.new(@component_builder)
          yield(then_builder)
          @main_builder.expressions << [ :if, resolve_expressions(condition), then_builder.expressions ]
          @main_builder
        end
        alias_method :if?, :if_

        def call(action_name, payload = {})
          @main_builder.expressions << [ :call, action_name, resolve_expressions(payload) ]
          @main_builder
        end

        def let(variable_name, value_expression)
          @main_builder.expressions << [ :let, variable_name.to_sym, resolve_expressions(value_expression) ]
          @main_builder
        end

        def log(*args)
          @main_builder.expressions << [ :log, *args.map { |arg| resolve_expressions(arg) } ]
          @main_builder
        end

        def state
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:state] }
        end

        def event
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:event] }
        end

        def payload
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:payload] }
        end

        def var
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:var] }
        end

        def this
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:this] }
        end

        def el
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:el] }
        end

        def dom
          Builder.new(@component_builder, main_builder: @main_builder).tap { |b| b.cursor = [:dom] }
        end

        def html
          HtmlBuilderProxy.new(self) # Let's leave HtmlBuilderProxy for now, it has its own logic.
        end

        def concat(*args)
          # concat is a function that returns an expression
          [ :concat, *args.map { |arg| resolve_expressions(arg) } ]
        end

        def fetch(url, method: :get, params: {}, service: nil, &block)
          options = {
            url: url,
            method: method,
            params: resolve_expressions(params),
            service: service&.to_s
          }.compact

          callback_builder = self.class.new(@component_builder)
          response_builder = ResponseBuilder.new # ResponseBuilder we will leave for now, it is simple
          callback_builder.instance_exec(response_builder, &block)

          @expressions << [ :fetch, options, callback_builder.expressions ]
          self
        end

        def method_missing(name, *args, &block)
          raise "Cannot call .#{name} here. Start a chain with state, dom, el, etc." if @cursor.nil?

          # Cursor-driven logic for various expression types
          case @cursor.first
          when :state, :event, :payload, :var, :param, :this
            @cursor << name.to_sym
          when :el
            @cursor = [ :element_attrs, name, {} ] # el.button
          when :element_attrs
            handle_element_attrs_chain(name, *args)
          when :dom
            handle_dom_chain(name, *args)
          when :dom_select
            # dom.select(...).add_class(...) -> this is already a command
            command = "dom_#{name}".to_sym
            @expressions << [ command, @cursor, *resolve_expressions(args) ]
            @cursor = nil # Resetting the cursor as the command has been executed
          else
            # Otherwise, this is a modifier method such as gt, lt, eq, and, or, not_
            @cursor = [ name, @cursor, *resolve_expressions(args) ]
          end

          self
        end

        def respond_to_missing?(name, include_private = false)
          true
        end

        # Allows the Builder itself to be used as an S-expression.
        def to_a
          @cursor
        end

        private

        def handle_element_attrs_chain(method_name, *args)
          # el.button.with(...)
          if method_name == :with
            @cursor[2].merge!(args.first)
          else
            raise "Unknown method .#{method_name} for `el` chain."
          end
        end

        def handle_dom_chain(method_name, *args)
          # dom.select(...)
          if method_name == :select
            @cursor = [ :dom_select, *resolve_expressions(args) ]
          else
            raise "Unknown method .#{method_name} for `dom` chain. Did you mean `dom.select(...)`?"
          end
        end

      end
    end
  end
end
