# frozen_string_literal: true

module Tailmix
  module Interpreter
    class Scope
      attr_reader :state, :param
      attr_accessor :locals

      def initialize(state: {}, param: {}, variants: {})
        @state    = state.transform_keys(&:to_s)
        @param    = param.transform_keys(&:to_s)
        @variants = variants.transform_keys(&:to_s)
        @locals   = {}
      end

      # resolve(:state, "user.name") -> deep-dig into @state["user"]["name"]
      # resolve(:variant, "size")    -> @variants["size"]
      def resolve(domain, path_string)
        root = case domain
        when :state   then @state
        when :param   then @param
        when :variant then @variants
        when :local   then @locals
        else return nil
        end

        return root if path_string.nil? || path_string.empty?

        path_string.split(".").reduce(root) do |current, key|
          return nil if current.nil?

          if current.is_a?(Hash)
            current.key?(key) ? current[key] : current[key.to_sym]
          elsif current.respond_to?(key)
            current.public_send(key)
          end
        end
      end
    end
  end
end
