# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix-powered state container for the Tabs component.
    class TabsState
      include Tailmix
      attr_reader :ui

      tailmix do
        state :active, default: "profile"

        element :root, "w-full"
        element :tablist, "flex gap-1 border-b border-gray-200 dark:border-gray-700"
        element :panels, "mt-4"

        element :tab, "px-4 py-2 text-sm font-medium rounded-t-lg transition-colors cursor-pointer" do
          on :click do
            set state.active, param.id
          end

          style condition: state.active == param.id do
            classes "border-b-2 border-blue-600 text-blue-600 dark:text-blue-500 dark:border-blue-500 bg-white dark:bg-gray-800"
            aria selected: true
            otherwise do
              classes "border-b-2 border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
              aria selected: false
            end
          end
        end

        element :panel do
          style condition: state.active == param.id do
            classes "block"
            aria hidden: false
            otherwise do
              classes "hidden"
              aria hidden: true
            end
          end
        end
      end

      def initialize(active:)
        @ui = tailmix(active: active)
      end
    end

    # The Arbre layout component for rendering tabs.
    class Tabs < BaseComponent
      builder_method :tabs

      def build(options = {})
        @active = options.delete(:active) || "profile"
        @tailmix_ui = @tabs_ui = TabsState.new(active: @active).ui

        super(@tabs_ui.root(options))

        # Root acts as the root data-tailmix-component
        set_attribute "data-tailmix-component", TabsState.name
        set_attribute "data-tailmix-state", @tabs_ui.state_json

        div @tabs_ui.tablist.merge(role: "tablist") do
          @nav_target = current_arbre_element
        end

        div @tabs_ui.panels do
          @panels_target = current_arbre_element
        end
      end

      def tab(label, id: nil, &block)
        id = (id || label.to_s.parameterize).to_s
        @nav_target << build_nav_item(label, id: id)
        @panels_target << build_panel(id: id, &block)
      end

      private

      def build_nav_item(label, id:)
        button @tabs_ui.tab(id: id).merge(role: "tab") do
          text_node label.is_a?(Symbol) ? label.to_s.humanize : label.to_s
        end
      end

      def build_panel(id:, &block)
        div @tabs_ui.panel(id: id).merge(role: "tabpanel") do
          block.call if block
        end
      end
    end
  end
end
