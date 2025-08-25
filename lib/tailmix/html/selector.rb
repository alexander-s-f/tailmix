# frozen_string_literal: true

module Tailmix
  module HTML
    class Selector
      def initialize(element_name, variant_string)
        @element_name = element_name
        @variant_string = variant_string
      end

      def to_h
        return {} unless @element_name

        key = "data-tailmix-#{@element_name}"
        { key => @variant_string }
      end
    end
  end
end
