# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered state container for interactive slide-over Drawers.
    class DrawerState
      include Tailmix

      tailmix do
        state :open, default: false
        variant :align, default: :right

        element :root, "fixed inset-0 z-50 overflow-hidden" do
          style condition: state.open do
            classes "pointer-events-auto"
            otherwise do
              classes "pointer-events-none"
            end
          end
        end

        element :backdrop, "fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity duration-300 ease-in-out" do
          on :click do
            set state.open, false
          end
          style condition: state.open do
            classes "opacity-100 visible"
            otherwise do
              classes "opacity-0 invisible"
            end
          end
        end

        element :panel, "fixed inset-y-0 w-full max-w-md bg-gray-950 border-gray-800 p-6 shadow-2xl flex flex-col transition-transform duration-300 ease-in-out" do
          style condition: state.open do
            classes "translate-x-0"
          end

          style condition: !state.open & (variant.align == :right) do
            classes "translate-x-full"
          end

          style condition: !state.open & (variant.align == :left) do
            classes "-translate-x-full"
          end

          match variant.align do
            on :right, "right-0 border-l"
            on :left, "left-0 border-r"
          end
        end

        element :close_btn, "rounded-lg p-1.5 inline-flex items-center justify-center text-gray-400 hover:text-white hover:bg-white/10 transition-colors cursor-pointer" do
          on :click do
            set state.open, false
          end
        end
      end

      def initialize(align: :right, open: false)
        @ui = tailmix(align: align, open: open)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering CRM-grade side slide-over panels.
    class Drawer < BaseComponent
      def build(options = {})
        align = options.delete(:align) || :right
        open = options.delete(:open) || false
        classes = options.delete(:class)

        @tailmix_ui = @drawer_ui = DrawerState.new(align: align, open: open).ui

        super(@drawer_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", DrawerState.name
        set_attribute "data-tailmix-state", @drawer_ui.state_json

        # Backdrop overlay dismissal
        div @drawer_ui.backdrop
      end

      # Slide-out drawer body panel
      def panel(options = {}, &block)
        div @drawer_ui.panel(options) do
          instance_eval(&block) if block
        end
      end

      # Header layout with optional dismiss trigger
      def header(title = nil, options = {}, &block)
        if title.is_a?(Hash)
          options = title
          title = nil
        end
        div({
          class: "flex items-center justify-between pb-4 border-b border-gray-800 mb-4"
        }.merge(options)) do
          h2 class: "text-lg font-semibold text-white" do
            if block
              instance_eval(&block)
            else
              text_node title
            end
          end
          button @drawer_ui.close_btn do
            span class: "sr-only" do
              text_node "Close"
            end
            text_node "×"
          end
        end
      end

      # Content scroll area
      def body(text = nil, options = {}, &block)
        if text.is_a?(Hash)
          options = text
          text = nil
        end
        div({
          class: "flex-grow overflow-y-auto pr-1"
        }.merge(options)) do
          if block
            instance_eval(&block)
          else
            text_node text
          end
        end
      end

      # Action buttons pane
      def footer(text = nil, options = {}, &block)
        if text.is_a?(Hash)
          options = text
          text = nil
        end
        div({
          class: "pt-4 border-t border-gray-800 mt-4 flex justify-end gap-3"
        }.merge(options)) do
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
