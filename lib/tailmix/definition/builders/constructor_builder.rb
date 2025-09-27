# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      # This class is the context (`self`) inside the `constructor` block.
      # It delegates calls (`on`, `dimension`) back to ElementBuilder,
      # but allows us to add new logic (`key`, `this`).
      class ConstructorBuilder
        def initialize(element_builder)
          @element_builder = element_builder
        end

        # `this` will be available inside `constructor`
        def this
          # Creating a proxy via our Scripting::Builder
          Scripting::Builder.new(@element_builder.component_builder).tap { |b| b.cursor = [ :this ] }
        end

        def key(name, to:, on:)
          # `to` - state.tabs -> [:state, :tabs]
          collection_name = to.to_a[1]
          # `on` - param.key -> [:param, :key]
          param_name = on.to_a[1]

          # Save configuration in parent ElementBuilder
          @element_builder.instance_variable_set(:@key_config, {
            name: name,
            collection: collection_name,
            param: param_name
          })
        end

        # Delegate all unknown methods back to ElementBuilder,
        # so that `on`, `dimension`, etc. are available within `constructor`.
        def method_missing(method_name, *args, **kwargs, &block)
          @element_builder.send(method_name, *args, **kwargs, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          @element_builder.respond_to?(method_name, include_private) || super
        end
      end
    end
  end
end