# frozen_string_literal: true

require_relative "docs"

module Tailmix
  module Dev
    class Tools
      attr_reader :definition, :component_class

      def initialize(component_class)
        @component_class = component_class
        @definition = component_class.tailmix_definition
      end

      def docs
        Dev::Docs.new(self).generate
      end
      alias_method :help, :docs

      def elements
        @definition.elements.values.map(&:name)
      end
    end
  end
end
