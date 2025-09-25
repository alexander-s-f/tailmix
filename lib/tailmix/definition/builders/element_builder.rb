# frozen_string_literal: true

require_relative "attribute_builder"
require_relative "dimension_builder"
require_relative "variant_builder"
require_relative "../scripting/helpers"

module Tailmix
  module Definition
    module Builders
      class ElementBuilder
        include Scripting::Helpers

        def initialize(name)
          @name = name
          @default_attributes = {}
          @dimensions = {}
          @compound_variants = []
          @event_bindings = []
          @attribute_bindings = {}
          @model_bindings = {}
          @each_config = nil
          @templates = {}
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

        def on(event_name, to:, with: {})
          @event_bindings << { event: event_name, action: to, with: with }
        end

        def param
          @_param_proxy ||= Scripting::ParamProxy.new
        end

        def event
          Scripting::EventProxy.new
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
          builder = DimensionBuilder.new(on: on)
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
          # FIX: Resolve expressions in event bindings before building the result.
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
            templates: @templates.freeze
          )
        end
      end
    end
  end
end