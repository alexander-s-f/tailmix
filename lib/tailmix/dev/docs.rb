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
            config[:variants].each do |variant_name, variant_def|
              output << "    - #{variant_name.inspect}:"
              variant_def.class_groups.each do |group|
                label = group[:options][:group] ? "(group: :#{group[:options][:group]})" : ""
                output << "      - classes #{label}: \"#{group[:classes].join(' ')}\""
              end
              output << "      - data: #{variant_def.data.inspect}" if variant_def.data.any?
              output << "      - aria: #{variant_def.aria.inspect}" if variant_def.aria.any?
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
