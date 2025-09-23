# frozen_string_literal: true
require_relative "element_attribute_proxy"

module Tailmix
  module Definition
    module Scripting
      # Proxy for `el`.
      # el.task_item -> ElementAttributeProxy.new(:task_item)
      class ElementProxy
        def method_missing(element_name, *args, &block)
          ElementAttributeProxy.new(element_name)
        end
      end
    end
  end
end
