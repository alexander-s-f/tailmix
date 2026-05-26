# frozen_string_literal: true

require "arbre"
require "tailmix"

module TailmixUi
  class BaseComponent < ::Arbre::Component
    include Tailmix

    attr_reader :tailmix_ui

    def initialize(*)
      super
      @component_name = self.class.name.demodulize.underscore.to_sym
    end

    def to_s
      if (defined?(Rails) && Rails.env.development?) || ENV["TAILMIX_ENV"] == "development" || ENV["TAILMIX_DEBUG"] == "true"
        set_attribute "data-tailmix-dev-component", self.class.name

        source_file, line_number = nil, nil
        if respond_to?(:build)
          source_file, line_number = method(:build).source_location
        end
        if source_file.nil?
          source_file, line_number = Object.const_source_location(self.class.name) rescue [nil, nil]
        end

        if source_file
          root_path = defined?(Rails) ? Rails.root.to_s : Dir.pwd
          relative_path = source_file.sub("#{root_path}/", "")
          set_attribute "data-tailmix-dev-source", "#{relative_path}:#{line_number}"
        end

        ui = @tailmix_ui || (respond_to?(:ui) ? self.ui : nil)
        if ui && ui.class.respond_to?(:definition)
          definition = ui.class.definition
          set_attribute "data-tailmix-dev-variants", definition[:variants].keys.to_json
          set_attribute "data-tailmix-dev-states", definition[:states].keys.to_json
          
          if ui.respond_to?(:state) && ui.state
            set_attribute "data-tailmix-dev-state", ui.state.to_json
          end

          if ui.respond_to?(:variants) && ui.variants
            set_attribute "data-tailmix-dev-current-variants", ui.variants.to_json
          end
        end
      end
      super
    end

    # Renders the SVG icon through the configured icon provider
    def render_icon(name, options = {})
      TailmixUi.configuration.icon_renderer.call(name, options)
    end

    # Auto-converts values to appropriate presentation tags
    def auto_component(value, options = {})
      case value
      when DateTime, Time, ActiveSupport::TimeWithZone
        value.strftime("%Y-%m-%d %H:%M")
      when TrueClass, FalseClass, NilClass
        # Render a badge
        insert_tag(Components::Badge, value, options)
      else
        value
      end
    end
  end
end
