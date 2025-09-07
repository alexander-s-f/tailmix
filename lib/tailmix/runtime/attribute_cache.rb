# frozen_string_literal: true

module Tailmix
  module Runtime
    class AttributeCache
      def initialize
        @cache = {}
      end

      def get(element_name)
        @cache[element_name.to_sym]
      end

      def set(element_name, attributes)
        @cache[element_name.to_sym] = attributes
      end

      def clear!
        @cache.clear
      end
    end
  end
end
