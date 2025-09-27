# frozen_string_literal: true

if defined?(Arbre)
  module Arbre
    class Context
      def tailmix(component_class, attributes = {}, &block)
        component = component_class.new(**attributes)
        ui_context = component.ui

        yield ui_context, component if block_given?
      end
    end
  end
end
