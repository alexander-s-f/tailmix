# frozen_string_literal: true

module Tailmix
  module Definition
    module Builders
      # This class is the context (`self`) within the `constructor` block.
      # It delegates calls (`on`, `dimension`) back to ElementBuilder,
      # but allows us to add new logic here in the future (`key`, `this`).
      class ConstructorBuilder
        def initialize(element_builder)
          @element_builder = element_builder
        end

        # `this` will be available inside `constructor`
        def this
          @_this_proxy ||= Scripting::ThisProxy.new
        end

        def key(_target, to:, on:)
          # `to` - state.tabs -> [:state, :tabs]
          collection_name = to.to_a[1]
          # `on` - param.name -> [:param, :name]
          param_name = on[1]

          # Saving configuration in the parent ElementBuilder
          @element_builder.instance_variable_set(:@key_config, {
            collection: collection_name,
            param: param_name
          })
        end

        # Delegate all unknown methods back to ElementBuilder,
        # so that `on`, `dimension`, etc. are available within `constructor`.
        def method_missing(method_name, *args, &block)
          @element_builder.send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          @element_builder.respond_to?(method_name, include_private) || super
        end
      end
    end
  end
end
