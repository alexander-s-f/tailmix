# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered state container for the Modal component.
    class ModalState
      include Tailmix
      attr_reader :ui

      tailmix do
        state :open, default: false

        # A default trigger button that can be embedded
        element :trigger, "px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition" do
          on :click do
            toggle state.open
          end
        end

        element :backdrop, "fixed inset-0 z-40 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm transition-all" do
          on :click do
            set state.open, false
          end

          style condition: state.open do
            classes "opacity-100 visible"
            otherwise do
              classes "opacity-0 invisible pointer-events-none"
            end
          end
        end

        element :panel, "relative z-50 w-full max-w-md rounded-xl bg-white shadow-2xl transition-all" do
          # Stops event bubbling so click inside doesn't close modal
          on :click do
            # no-op
          end

          style condition: state.open do
            classes "scale-100 opacity-100"
            otherwise do
              classes "scale-95 opacity-0 pointer-events-none"
            end
          end
        end

        element :close_btn, "rounded-lg p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors" do
          on :click do
            set state.open, false
          end
        end
      end

      def initialize(open: false)
        @ui = tailmix(open: open)
      end
    end

    # The Arbre layout component for rendering modals.
    class Modal < BaseComponent
      builder_method :modal

      def build(options = {})
        @open = options.delete(:open) || false
        @modal_ui = ModalState.new(open: @open).ui

        super(@modal_ui.backdrop(options))

        # Backdrop acts as the root data-tailmix-component
        set_attribute "data-tailmix-component", ModalState.name
        set_attribute "data-tailmix-state", @modal_ui.state_json

        # Assign panel target directly from div return value
        @panel_target = div(@modal_ui.panel)
      end

      def add_child(child)
        if @panel_target
          @panel_target << child
        else
          super
        end
      end

      def children?
        @panel_target&.children?
      end
    end
  end
end
