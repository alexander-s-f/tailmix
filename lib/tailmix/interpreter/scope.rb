# frozen_string_literal: true

module Tailmix
  module Interpreter
    class Scope
      attr_reader :state, :param

      def initialize(state: {}, param: {})
        @state = state.transform_keys(&:to_s)
        @param = param.transform_keys(&:to_s)
        @locals = {}
      end

      # scope.resolve(:state, "user.name")
      def resolve(domain, path_string)
        root = case domain
        when :state then @state
        when :param then @param
        when :local then @locals
        else return nil
        end

        keys = path_string.split(".")

        keys.reduce(root) do |current, key|
          return nil if current.nil?

          if current.is_a?(Hash)
            if current.key?(key)
              current[key]
            else
              current[key.to_sym]
            end
          elsif current.respond_to?(key)
            current.public_send(key)
          else
            nil
          end
        end
      end
    end
  end
end


