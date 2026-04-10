# frozen_string_literal: true

require_relative "effect_builder"

module Tailmix
  module DSL
    # Wraps two EffectBuilders: one for the truthy branch, one for the optional else branch.
    # Used by ElementParser#style to support an `otherwise` clause:
    #
    #   style condition: state.open do
    #     classes "visible opacity-100"
    #     otherwise "invisible opacity-0"
    #   end
    #
    #   style condition: state.open do
    #     classes "visible"
    #     aria expanded: true
    #     otherwise do
    #       classes "hidden"
    #       aria expanded: false
    #     end
    #   end
    class StyleBuilder < ParserContext
      attr_reader :consequent, :alternate

      def initialize
        @consequent = EffectBuilder.new
        @alternate  = nil
      end

      # --- Forward effect DSL to the truthy builder ---

      def classes(val) = @consequent.classes(val)
      def data(hash)   = @consequent.data(hash)
      def aria(hash)   = @consequent.aria(hash)
      def prop(hash)   = @consequent.prop(hash)
      def html(expr)   = @consequent.html(expr)

      # --- Else branch ---

      def otherwise(class_string = nil, &block)
        builder = EffectBuilder.new
        builder.classes(class_string) if class_string
        builder.instance_eval(&block) if block
        @alternate = builder.effect
      end
    end
  end
end
