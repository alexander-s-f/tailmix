# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered state container for collapsible Accordion Panels.
    class AccordionPanelState
      include Tailmix

      tailmix do
        state :open, default: false

        element :root, "w-full border-b border-gray-800"

        element :trigger, "w-full flex justify-between items-center py-4 text-left font-semibold text-gray-200 hover:text-white transition-colors cursor-pointer focus:outline-none" do
          on :click do
            toggle state.open
          end
        end

        element :chevron, "w-5 h-5 text-gray-400 transition-transform duration-200 ease-out" do
          style condition: state.open do
            classes "transform rotate-180 text-white"
          end
        end

        element :content, "overflow-hidden transition-all duration-200 ease-in-out" do
          style condition: state.open do
            classes "max-h-96 py-3 opacity-100"
            otherwise do
              classes "max-h-0 py-0 opacity-0 pointer-events-none"
            end
          end
        end
      end

      def initialize(open: false)
        @ui = tailmix(open: open)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering collapsible sections.
    class AccordionPanel < BaseComponent
      def build(options = {})
        open = options.delete(:open) || false
        classes = options.delete(:class)

        @tailmix_ui = @panel_ui = AccordionPanelState.new(open: open).ui

        super(@panel_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", AccordionPanelState.name
        set_attribute "data-tailmix-state", @panel_ui.state_json
      end

      # Section header trigger action button with toggle triggers
      def trigger(title = nil, options = {}, &block)
        if title.is_a?(Hash)
          options = title
          title = nil
        end
        button @panel_ui.trigger(options) do
          span class: "flex-grow" do
            if block
              instance_eval(&block)
            else
              text_node title
            end
          end
          span @panel_ui.chevron do
            text_node "▼"
          end
        end
      end

      # Section expandable panel container
      def panel(&block)
        div @panel_ui.content do
          instance_eval(&block) if block
        end
      end
    end
  end
end
