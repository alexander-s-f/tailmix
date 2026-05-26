# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered CVA state container for Toast Notifications.
    class ToastState
      include Tailmix

      tailmix do
        state :open, default: false
        variant :color, default: :success

        element :root, "fixed top-5 right-5 z-50 flex items-center w-full max-w-sm p-4 rounded-xl border border-gray-800 bg-gray-950/95 backdrop-blur-md shadow-2xl transition-all duration-300" do
          style condition: state.open do
            classes "translate-x-0 opacity-100 scale-100"
            otherwise do
              classes "translate-x-10 opacity-0 scale-95 pointer-events-none"
            end
          end

          match variant.color do
            on :success, "border-green-800/80 text-green-200 bg-green-950/90"
            on :danger, "border-red-800/80 text-red-200 bg-red-950/90"
            on :info, "border-sky-800/80 text-sky-200 bg-sky-950/90"
            on :warning, "border-yellow-800/80 text-yellow-200 bg-yellow-950/90"
          end
        end

        element :close_btn, "ml-auto -mx-1.5 -my-1.5 rounded-lg p-1.5 inline-flex items-center justify-center text-gray-400 hover:text-white hover:bg-white/10 transition-colors cursor-pointer" do
          on :click do
            set state.open, false
          end
        end
      end

      def initialize(color: :success, open: false)
        @ui = tailmix(color: color, open: open)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering floating Toast Notifications.
    class Toast < BaseComponent
      def build(options = {})
        color = options.delete(:color) || :success
        open = options.delete(:open) || false
        classes = options.delete(:class)

        @tailmix_ui = @toast_ui = ToastState.new(color: color, open: open).ui

        super(@toast_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", ToastState.name
        set_attribute "data-tailmix-state", @toast_ui.state_json
      end

      # Notification body text / container
      def body(text = nil, &block)
        div class: "flex-grow text-sm font-medium mr-3" do
          if block
            instance_eval(&block)
          else
            text_node text
          end
        end
      end

      # Floating close action button
      def close_button
        button @toast_ui.close_btn do
          span class: "sr-only" do
            text_node "Close"
          end
          text_node "×"
        end
      end
    end
  end
end
