# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered CVA state container for Tooltips.
    class TooltipState
      include Tailmix

      tailmix do
        state :active, default: false

        element :root, "relative inline-block"

        element :trigger, "inline-block" do
          on :mouseenter do
            set state.active, true
          end
          on :mouseleave do
            set state.active, false
          end
        end

        element :bubble, "absolute bottom-full left-1/2 z-50 mb-2 -translate-x-1/2 px-2.5 py-1 text-xs font-semibold rounded-lg bg-gray-900 border border-gray-800 text-white shadow-lg pointer-events-none transition-all duration-150" do
          style condition: state.active do
            classes "opacity-100 visible translate-y-0 scale-100"
            otherwise do
              classes "opacity-0 invisible translate-y-1 scale-95"
            end
          end
        end
      end

      def initialize
        @ui = tailmix
      end
      attr_reader :ui
    end

    # The Arbre component for rendering interactive Tooltips.
    class Tooltip < BaseComponent
      def build(options = {})
        classes = options.delete(:class)
        @tailmix_ui = @tooltip_ui = TooltipState.new.ui

        super(@tooltip_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", TooltipState.name
        set_attribute "data-tailmix-state", @tooltip_ui.state_json
      end

      # Element wrapper that receives hover listeners in the browser
      def trigger(options = {}, &block)
        div @tooltip_ui.trigger(options) do
          instance_eval(&block) if block
        end
      end

      # Popover bubble displaying the information
      def bubble(text = nil, options = {}, &block)
        div @tooltip_ui.bubble(options) do
          if block
            instance_eval(&block)
          else
            text_node text
          end
        end
      end
    end
  end
end
