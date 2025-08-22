# frozen_string_literal: true

module Tailmix
  module Runtime
    # Represents a callable action at runtime that can apply a set of
    # predefined mutations to its context.
    class Action
      attr_reader :context, :definition

      def initialize(context, action_name)
        @context = context
        @action_name = action_name.to_sym
        @definition = context.definition.actions[@action_name]
        raise Error, "Action `#{@action_name}` not found." unless @definition
      end

      # Applies the mutations to the context immutably, returning a new context.
      # @return [Context] A new, modified context instance.
      def apply
        new_context = context.dup

        action_on_clone = self.class.new(new_context, @action_name)

        action_on_clone.apply!
      end

      def apply!
        definition.mutations.each do |element_name, mutations_hash|
          attributes_object = context.live_attributes_for(element_name)

          attributes_object.merge!(mutations_hash)
        end
        context
      end

      # Serializes the action's definition into a hash for the JS bridge.
      # @return [Hash]
      def to_h
        {
          method: definition.action,
          elements: definition.mutations.transform_values do |mutations|
            result = {}
            result[:classes] = mutations[:class] if mutations[:class]
            result[:data] = mutations[:data] if mutations[:data]
            result
          end
        }
      end
    end
  end
end
