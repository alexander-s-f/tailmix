# frozen_string_literal: true

require "arbre"
require "tailmix"

module TailmixUi
  class BaseComponent < ::Arbre::Component
    include Tailmix

    def initialize(*)
      super
      @component_name = self.class.name.demodulize.underscore.to_sym
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
