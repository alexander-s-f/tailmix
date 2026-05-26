# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix CVA (Class Variance Authority) state and variant configuration for Card.
    class CardState
      include Tailmix
      attr_reader :ui

      tailmix do
        variant :size, default: :default

        element :container, "px-4 2xl:px-0" do
          match variant.size do
            on :default, "text-base"
            on :center, "mx-auto max-w-2xl text-base"
          end
        end

        element :title, "font-semibold mb-2" do
          match variant.size do
            on :default, "text-xl text-white"
            on :center, "text-green-500 mb-2"
          end
        end

        element :content, "md:space-y-4 sm:space-y-4 rounded-lg border p-6 border-gray-700 bg-gray-800 mb-6 md:mb-8"
        element :dl, "sm:flex items-center justify-between gap-4"
        element :dt, "font-normal mb-1 sm:mb-0 text-gray-400"
        element :dd, "font-medium text-white sm:text-end"
      end

      def initialize(size:)
        @ui = tailmix(size: size)
      end
    end

    # The Arbre component for rendering Card.
    class Card < BaseComponent
      builder_method :card

      def build(title = nil, attributes = {}, &block)
        if title.is_a?(Hash) && attributes.blank?
          attributes = title
          title = nil
        end

        @variant = attributes.delete(:variant) || :default

        # Dynamically build state/facade using CardState
        @tailmix_ui = @card_ui = CardState.new(size: @variant).ui

        super(@card_ui.container(attributes))

        if title.present?
          h2 title, class: @card_ui.title[:class]
        end

        @body = div(class: @card_ui.content[:class])
      end

      def line(*args, &block)
        defaults = { if: true }
        label = args[0]
        options = args.extract_options! || {}
        options = defaults.merge(options)
        condition = options.delete(:if)

        return unless condition

        if block_given?
          value = block.call
        else
          value = args[1]
        end

        placeholder = options.delete(:placeholder)
        if (value.nil? || value == "") && placeholder.present?
          value = placeholder
        else
          value = auto_component(value, options)
        end

        build_row(label, value, options)
      end

      def build_row(label, value, options)
        dl class: @card_ui.dl[:class] do
          dt(label, class: @card_ui.dt[:class])
          dd(value, class: @card_ui.dd[:class])
        end
      end

      def add_child(child)
        if @body
          @body << child
        else
          super
        end
      end

      def children?
        @body.children?
      end
    end
  end
end
