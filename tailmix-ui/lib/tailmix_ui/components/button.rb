# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix CVA (Class Variance Authority) state and variant configuration for Button.
    class ButtonState
      include Tailmix
      attr_reader :ui

      tailmix do
        variant :size, default: :default
        variant :color, default: :default

        element :btn, "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer justify-center transition" do
          match variant.size do
            on :default, "px-3 py-2 rounded-lg text-sm"
            on :xs, "px-1.5 py-1 rounded-md text-xs"
            on :sm, "px-2 py-1 rounded-lg text-sm"
            on :md, "px-3 py-2 rounded-lg text-sm"
            on :lg, "px-3.5 py-2 rounded-lg text-base"
            on :xl, "px-4 py-2.5 rounded-lg text-base"
          end

          match variant.color do
            on :default, "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-800"
            on :primary, "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-800"
            on :danger, "text-white bg-red-600 hover:bg-red-700 focus:ring-red-800"
            on :success, "text-white bg-green-600 hover:bg-green-700 focus:ring-green-800"
            on :warning, "text-white bg-yellow-500 hover:bg-yellow-600 focus:ring-yellow-300"
            on :neutral, "text-white bg-gray-600 hover:bg-gray-700 focus:ring-gray-800"
            on :info, "text-white bg-sky-600 hover:bg-sky-700 focus:ring-sky-800"
            on :indigo, "text-white bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-800"
          end
        end
      end

      def initialize(size:, color:)
        @ui = tailmix(size: size, color: color)
      end
    end

    # The Arbre component for rendering Button.
    class Button < BaseComponent
      builder_method :btn

      def tag_name
        @tag_name
      end

      def build(label, path = nil, options = {})
        if label.is_a?(Hash) && path.nil?
          options = label
          label = nil
        elsif path.is_a?(Hash) && options.empty?
          options = path
          path = nil
        end

        @tag_name = options.delete(:tag) || (path ? "a" : "button")
        confirm = options.delete(:confirm)
        icon = options.delete(:icon)
        classes = options.delete(:class)
        size = options.delete(:size) || :default
        color = options.delete(:state) || options.delete(:color) || :default

        if confirm
          options[:data] ||= {}
          options[:data][:confirm] = confirm
        end

        options[:href] = path if @tag_name == "a" && path
        label_text = label.is_a?(Symbol) ? label.to_s.humanize.titleize : label

        # Dynamically build state/facade using ButtonState
        @tailmix_ui = @btn_ui = ButtonState.new(size: size, color: color).ui

        super(@btn_ui.btn(options))

        add_class(classes) if classes

        if icon.present?
          span class: "flex items-stretch transition-all duration-200" do
            span class: "flex items-center" do
              span class: "flex items-center justify-center mr-1.5" do
                text_node render_icon(icon)
              end
              if label_text.present?
                span label_text
              end
            end
          end
        else
          span label_text if label_text.present?
        end
      end
    end
  end
end
