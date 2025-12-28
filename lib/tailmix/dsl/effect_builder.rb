# frozen_string_literal: true

module Tailmix
  module DSL
    class EffectBuilder < ParserContext
      attr_reader :effect

      def initialize
        @effect = AST::AttributeEffect.new(
          classes: [],
          data: {},
          aria: {},
          props: {},
          other: {}
        )
      end

      def classes(val)
        @effect.classes.concat(val.split)
      end

      def data(hash)
        @effect.data.merge!(hash)
      end

      def aria(hash)
        @effect.aria.merge!(hash)
      end

      def prop(hash)
        @effect.props.merge!(hash)
      end
    end
  end
end
