# frozen_string_literal: true

module Tailmix
  module Dev
    class Docs

      def initialize(tools)
        @tools = tools
        @definition = tools.definition
        @component_class_name = tools.component_class
      end

      def generate
        output = ["== Tailmix Docs for #{@component_class_name} =="]

        signature = generate_signature
        output << "Signature: `initialize(#{signature})`" unless signature.empty?
        output << ""

        output << generate_dimensions_docs
        output << ""
        output << generate_actions_docs
        output << ""
        output << generate_stimulus_docs

        output.join("\n")
      end

      private

      def generate_signature
        all_dimensions
          .map { |name, config| "#{name}: #{config[:default].inspect}" if config.key?(:default) }
          .compact
          .join(", ")
      end

      def generate_dimensions_docs
        output = []

        if all_dimensions.any?
          output << "Dimensions:"
          all_dimensions.each do |dim_name, config|
            default_info = config[:default] ? "(default: #{config[:default].inspect})" : ""
            output << "  - #{dim_name} #{default_info}"
            config[:options].each do |option_key, option_value|
              output << "    - #{option_key.inspect}: \"#{option_value.join(' ')}\""
            end
          end
        else
          output << "No dimensions defined."
        end

        output.join("\n")
      end

      def generate_actions_docs
        output = []
        actions = @definition.actions

        if actions.any?
          output << "Actions:"
          actions.keys.each do |action_name|
            output << "  - :#{action_name}"
          end
        else
          output << "No actions defined."
        end

        output.join("\n")
      end

      def generate_stimulus_docs
        @tools.stimulus.scaffold(show_docs: true)
      end

      def all_dimensions
        @_all_dimensions ||= @definition.elements.values.flat_map(&:dimensions).reduce({}, :merge)
      end
    end
  end
end
