# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered CVA state container for the Sidebar component suite.
    class SidebarState
      include Tailmix

      tailmix do
        state :open, default: false

        element :root, "min-h-screen flex w-full bg-gray-950"

        # Mobile menu backdrop click catcher
        element :backdrop, "md:hidden fixed inset-0 z-40 bg-black/60 backdrop-blur-sm transition-all duration-300" do
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

        # Navigation drawer container
        element :drawer, "fixed top-0 bottom-0 left-0 z-50 w-64 border-r border-gray-800 bg-gray-950 p-4 transition-transform duration-300 md:translate-x-0 md:static flex flex-col" do
          style condition: state.open do
            classes "translate-x-0"
            otherwise do
              classes "-translate-x-full"
            end
          end
        end

        # Mobile navbar toggle menu trigger button
        element :toggle, "md:hidden p-2 text-gray-400 hover:text-white rounded-lg cursor-pointer" do
          on :click do
            toggle state.open
          end
        end

        element :main, "flex-grow flex flex-col overflow-x-hidden min-h-screen"
      end

      def initialize(open: false)
        @ui = tailmix(open: open)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering Sidebar-based application layouts.
    class Sidebar < BaseComponent
      def build(options = {})
        open = options.delete(:open) || false
        classes = options.delete(:class)
        @tailmix_ui = @sidebar_ui = SidebarState.new(open: open).ui

        super(@sidebar_ui.root(options))
        add_class(classes) if classes

        set_attribute "data-tailmix-component", SidebarState.name
        set_attribute "data-tailmix-state", @sidebar_ui.state_json

        # Mobile click away overlay backdrop
        div class: "sidebar-backdrop", "data-tailmix-element": "backdrop"
      end

      # Left navigation drawer shell
      def drawer(options = {}, &block)
        div @sidebar_ui.drawer(options) do
          instance_eval(&block) if block
        end
      end

      # Right-side main content wrapper
      def main(options = {}, &block)
        div @sidebar_ui.main(options) do
          instance_eval(&block) if block
        end
      end
    end
  end
end
