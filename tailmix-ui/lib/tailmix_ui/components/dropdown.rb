# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix CVA state and variant configuration for Dropdown.
    class DropdownState
      include Tailmix

      tailmix do
        state :open, default: false
        variant :align, default: :right
        variant :size, default: :md

        element :root, "relative inline-block text-left"

        element :trigger, "inline-flex items-center" do
          on :click do
            toggle state.open
          end
        end

        element :backdrop, "fixed inset-0 z-30 bg-transparent cursor-default" do
          on :click do
            set state.open, false
          end

          style condition: state.open do
            classes "block"
            otherwise do
              classes "hidden"
            end
          end
        end

        element :menu, "absolute mt-2 z-40 origin-top-right rounded-xl border border-gray-800 bg-gray-900/95 backdrop-blur-md p-1.5 shadow-2xl ring-1 ring-black/5 focus:outline-none transition-all duration-150" do
          style condition: state.open do
            classes "scale-100 opacity-100 visible"
            otherwise do
              classes "scale-95 opacity-0 invisible pointer-events-none"
            end
          end
          
          match variant.align do
            on :right, "right-0"
            on :left, "left-0"
          end

          match variant.size do
            on :sm, "w-48"
            on :md, "w-56"
            on :lg, "w-72"
          end
        end

        element :item, "flex w-full items-center px-3 py-2 text-sm font-medium rounded-lg text-gray-300 hover:bg-gray-800/80 hover:text-white transition-colors cursor-pointer" do
          on :click do
            set state.open, false
          end
        end
      end

      def initialize(align: :right, size: :md)
        @ui = tailmix(align: align, size: size)
      end
      attr_reader :ui
    end

    # The Arbre component for rendering Dropdown.
    class Dropdown < BaseComponent
      def build(options = {})
        align = options.delete(:align) || :right
        size = options.delete(:size) || :md
        classes = options.delete(:class)

        @tailmix_ui = @dropdown_ui = DropdownState.new(align: align, size: size).ui

        super(@dropdown_ui.root(options))
        add_class(classes) if classes

        # Click away backdrop
        div class: "dropdown-backdrop", "data-tailmix-element": "backdrop"
      end

      # Nested builder for the trigger element
      def trigger(label, options = {}, &block)
        classes = options.delete(:class)
        btn_options = @dropdown_ui.trigger({
          class: "flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-800 bg-gray-900 text-white hover:bg-gray-800 transition-colors #{classes}"
        }.merge(options))

        button btn_options do
          if block
            instance_eval(&block)
          else
            span label
            span class: "text-gray-400 text-xs ml-0.5" do
              text_node "▾"
            end
          end
        end
      end

      # Nested builder for the menu container
      def menu(options = {}, &block)
        classes = options.delete(:class)
        dropdown_instance = self
        div({
          class: "dropdown-menu",
          "data-tailmix-element": "menu"
        }.merge(options)) do
          add_class(classes) if classes
          if block
            dropdown_instance.instance_eval(&block)
          end
        end
      end

      # Nested builder for menu item
      def item(label = nil, options = {}, &block)
        classes = options.delete(:class)
        tag_options = {
          class: "dropdown-item",
          "data-tailmix-element": "item"
        }.merge(options)

        if options[:href]
          a label, tag_options do
            instance_eval(&block) if block
          end
        else
          button label, tag_options do
            instance_eval(&block) if block
          end
        end
      end
    end
  end
end

# Define custom builder method for Dropdown to avoid standard HTML5 <menu> tag collision
module Arbre
  class Element
    module BuilderMethods
      def dropdown(*args, &block)
        tag = build_tag ::TailmixUi::Components::Dropdown, *args
        if block
          with_current_arbre_element tag do
            tag.instance_eval(&block)
          end
        end
        current_arbre_element.add_child(tag)
        tag
      end
    end
  end
end
