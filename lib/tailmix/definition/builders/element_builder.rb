# frozen_string_literal: true

require_relative "attribute_builder"
require_relative "dimension_builder"
require_relative "variant_builder"
require_relative "constructor_builder"
require_relative "../scripting/helpers"

module Tailmix
  module Definition
    module Builders
      class ElementBuilder
        include Scripting::Helpers
        attr_reader :component_builder

        def initialize(name, component_builder)
          @name = name
          @component_builder = component_builder
          @default_attributes = {}
          @dimensions = {}
          @compound_variants = []
          @event_bindings = []
          @attribute_bindings = {}
          @model_bindings = {}
          @each_config = nil
          @templates = {}
          @key_config = nil
        end

        def constructor(&block)
          constructor_builder = ConstructorBuilder.new(self)
          param_builder = Scripting::Builder.new(@component_builder).tap { |b| b.cursor = [ :param ] }
          constructor_builder.instance_exec(param_builder, &block)
        end

        def state
          Scripting::Builder.new(@component_builder).tap { |b| b.cursor = [ :state ] }
        end

        def attributes
          @attributes_builder ||= AttributeBuilder.new
        end

        def method_missing(name, *args, &block)
          attribute_name = name.to_s.chomp("=").to_sym
          @default_attributes[attribute_name] = args.first
        end

        def respond_to_missing?(*_args)
          true
        end

        def on(event_name, to: nil, with: {}, &block)
          action_name = to

          if block_given?
            raise "Cannot provide both `to:` and a block to `on`" if to
            action_name = :"#{@name}_#{event_name}_handler"
            @component_builder.action(action_name, &block)
          end

          return unless action_name

          @event_bindings << { event: event_name, action: action_name, with: with }
        end

        def param
          Scripting::Builder.new(@component_builder).tap { |b| b.cursor = [ :param ] }
        end

        def event
          Scripting::Builder.new(@component_builder).tap { |b| b.cursor = [ :event ] }
        end

        def model(attribute_name, to:, on: :input, action: nil, debounce: nil)
          @model_bindings[attribute_name.to_sym] = {
            state: to.to_sym,
            event: on,
            action: action,
            debounce: debounce
          }.compact
        end

        def dimension(name, on: nil, &block)
          resolved_on = resolve_expressions(on)

          builder = DimensionBuilder.new(on: resolved_on)
          builder.instance_eval(&block)
          @dimensions[name.to_sym] = builder.build_dimension
        end

        def compound_variant(on:, &block)
          builder = VariantBuilder.new
          builder.instance_eval(&block)

          @compound_variants << {
            on: on,
            modifications: builder.build_variant
          }
        end

        def bind(attribute_name, to:)
          @attribute_bindings[attribute_name.to_sym] = resolve_expressions(to)
        end

        def build_definition
          resolved_event_bindings = @event_bindings.map do |binding|
            binding.merge(with: resolve_expressions(binding[:with]))
          end

          Result::Element.new(
            name: @name,
            attributes: attributes.build_definition,
            default_attributes: @default_attributes.freeze,
            dimensions: @dimensions.freeze,
            compound_variants: @compound_variants.freeze,
            event_bindings: resolved_event_bindings.freeze,
            attribute_bindings: @attribute_bindings.freeze,
            model_bindings: @model_bindings.freeze,
            each_config: @each_config,
            templates: @templates.freeze,
            key_config: @key_config
          )
        end
      end
    end
  end
end
